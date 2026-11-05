-module(p65_lote).
-behaviour(gen_statem).

-export([start_link/1, pujar/4, retirar/1, info/1]).
-export([init/1, callback_mode/0,
         abierto/3, ultima_llamada/3, adjudicado/3, retirado/3]).

-record(d, {id, peso, base, precio, incremento, ganador = none,
            abierto_ms, ultima_ms, vence = 0}).

name(Id) -> {global, {lote, Id}}.

start_link(#{id := Id} = Cfg) ->
  gen_statem:start_link(name(Id), ?MODULE, Cfg, []).

pujar(Id, Postor, Monto, Canal) -> llamar(Id, {pujar, Postor, Monto, Canal}).
retirar(Id) -> llamar(Id, retirar).
info(Id) -> llamar(Id, info).

llamar(Id, Msg) ->
  try gen_statem:call(name(Id), Msg, 5000)
  catch exit:{noproc, _} -> {error, lote_inexistente}
  end.

callback_mode() -> state_functions.

init(#{id := Id, peso_kg := Peso, base_por_kg := Base} = Cfg) ->
  D0 = #d{id = Id, peso = Peso, base = Base, precio = Base,
          incremento = maps:get(incremento, Cfg, 1),
          abierto_ms = maps:get(abierto_ms, Cfg, 10000),
          ultima_ms = maps:get(ultima_ms, Cfg, 5000)},
  case recuperar(D0) of
    {nuevo, D} ->
      {ok, _} = p65_bitacora:registrar(Id, abre, none, Base, sistema),
      {ok, abierto, con_vence(D, D#d.abierto_ms), [{state_timeout, D#d.abierto_ms, ultima}]};
    {abierto, D} ->
      {ok, abierto, con_vence(D, D#d.abierto_ms), [{state_timeout, D#d.abierto_ms, ultima}]};
    {Final, D} ->
      {ok, Final, D}
  end.

%% Reconstruye el estado desde la bitacora (reinicio tras una falla)
recuperar(D0) ->
  lists:foldl(
    fun({_, _, abre, _, _, _, _}, {_, D}) -> {abierto, D};
       ({_, _, puja, P, M, _, _}, {_, D}) -> {abierto, D#d{precio = M, ganador = P}};
       ({_, _, adjudicado, _, _, _, _}, {_, D}) -> {adjudicado, D};
       ({_, _, retirado, _, _, _, _}, {_, D}) -> {retirado, D};
       (_, Acc) -> Acc
    end, {nuevo, D0}, p65_bitacora:eventos(D0#d.id)).

%% ---- Estados ----
abierto({call, From}, {pujar, P, M, C}, D) -> aceptar(From, P, M, C, D);
abierto({call, From}, retirar, D) -> retirar_lote(From, D);
abierto(state_timeout, ultima, D) ->
  {next_state, ultima_llamada, con_vence(D, D#d.ultima_ms),
   [{state_timeout, D#d.ultima_ms, martillazo}]};
abierto(T, E, D) -> comun(T, E, D, abierto).

ultima_llamada({call, From}, {pujar, P, M, C}, D) -> aceptar(From, P, M, C, D);
ultima_llamada({call, From}, retirar, D) -> retirar_lote(From, D);
ultima_llamada(state_timeout, martillazo, #d{id = Id, ganador = G, precio = Pr} = D) ->
  {ok, _} = p65_bitacora:registrar(Id, adjudicado, G, Pr, sistema),
  {next_state, adjudicado, D#d{vence = 0}};
ultima_llamada(T, E, D) -> comun(T, E, D, ultima_llamada).

adjudicado({call, From}, {pujar, P, M, C}, D) -> rechazar(From, P, M, C, D, lote_cerrado);
adjudicado(T, E, D) -> comun(T, E, D, adjudicado).

retirado({call, From}, {pujar, P, M, C}, D) -> rechazar(From, P, M, C, D, lote_retirado);
retirado(T, E, D) -> comun(T, E, D, retirado).

%% ---- Logica ----
aceptar(From, P, M, C, #d{id = Id} = D) ->
  Min = minimo(D),
  case M >= Min of
    true ->
      {ok, Seq} = p65_bitacora:registrar(Id, puja, P, M, C),
      %% Regla de extension: toda puja valida reinicia el reloj en 'abierto'
      {next_state, abierto, con_vence(D#d{precio = M, ganador = P}, D#d.abierto_ms),
       [{reply, From, {ok, Seq}}, {state_timeout, D#d.abierto_ms, ultima}]};
    false ->
      rechazar(From, P, M, C, D, {puja_baja, Min})
  end.

rechazar(From, P, M, C, #d{id = Id}, Motivo) ->
  {ok, _} = p65_bitacora:registrar(Id, puja_rechazada, P, M, C),
  {keep_state_and_data, [{reply, From, {error, Motivo}}]}.

retirar_lote(From, #d{id = Id, ganador = G, precio = Pr} = D) ->
  {ok, _} = p65_bitacora:registrar(Id, retirado, G, Pr, sistema),
  {next_state, retirado, D#d{vence = 0}, [{reply, From, ok}]}.

%% Instante (ms, system_time) en que vence el reloj actual; la UI lo usa para la cuenta regresiva
con_vence(D, Ms) -> D#d{vence = erlang:system_time(millisecond) + Ms}.

minimo(#d{ganador = none, base = Base}) -> Base;
minimo(#d{precio = Pr, incremento = Inc}) -> Pr + Inc.

comun({call, From}, info, D, Estado) ->
  {keep_state_and_data, [{reply, From, info_map(Estado, D)}]};
comun({call, From}, _, _, Estado) ->
  {keep_state_and_data, [{reply, From, {error, {no_permitido, Estado}}}]};
comun(_, _, _, _) ->
  keep_state_and_data.

info_map(Estado, #d{id = Id, peso = Peso, base = Base, precio = Pr, ganador = G,
                    vence = Vence} = D) ->
  #{id => Id, estado => Estado, peso_kg => Peso, base_por_kg => Base,
    precio_por_kg => Pr, minimo_por_kg => minimo(D), ganador => G,
    total => Peso * Pr, vence_ms => Vence}.
