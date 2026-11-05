%%% Capa de negocio de la API: valida la entrada, llama a los procesos OTP y
%%% devuelve mapas listos para JSON. No sabe nada de HTTP (eso es p65_api_handler).
%%% Los errores son {error, {CodigoHttp, MapaJson}}.
-module(p65_api).

-export([id_bin/1, lotes/0, lote/1, crear/1, pujar/2, retirar/1,
         eventos_de_lote/1, ultimos/1, desde/2, evento_map/1, metricas/0]).

-define(MAX_LOTES, 1000).

%% ------------------------------------------------------------------
%% Identificadores: el id interno puede ser entero, binario o tupla (el
%% simulador usa {Corrida, N}); hacia afuera siempre es una cadena.
%% ------------------------------------------------------------------

id_bin(I) when is_integer(I) -> integer_to_binary(I);
id_bin(B) when is_binary(B) -> B;
id_bin(A) when is_atom(A) -> atom_to_binary(A, utf8);
id_bin(T) when is_tuple(T) ->
  iolist_to_binary(lists:join($-, [id_bin(X) || X <- tuple_to_list(T)]));
id_bin(X) -> iolist_to_binary(io_lib:format("~w", [X])).

ids() ->
  lists:sort([Id || {lote, Id} <- global:registered_names()]).

buscar(Bin) ->
  case [Id || Id <- ids(), id_bin(Id) =:= Bin] of
    [Id | _] -> {ok, Id};
    [] -> {error, {404, #{error => lote_inexistente}}}
  end.

%% ------------------------------------------------------------------
%% Lotes
%% ------------------------------------------------------------------

lotes() ->
  [info_map(I) || Id <- ids(), I <- [safe_info(Id)], is_map(I)].

lote(IdBin) ->
  case buscar(IdBin) of
    {ok, Id} ->
      case safe_info(Id) of
        I when is_map(I) -> {ok, info_map(I)};
        _ -> {error, {503, #{error => lote_no_disponible}}}
      end;
    Error -> Error
  end.

crear(Body) ->
  maybe_ok(
    [fun() -> validar_id(maps:get(<<"id">>, Body, undefined)) end,
     fun() -> num(Body, <<"peso_kg">>, undefined, 1, 5000) end,
     fun() -> num(Body, <<"base_por_kg">>, undefined, 1, 100000) end,
     fun() -> num(Body, <<"incremento">>, 1, 1, 100000) end,
     fun() -> num(Body, <<"abierto_ms">>, 30000, 100, 600000) end,
     fun() -> num(Body, <<"ultima_ms">>, 10000, 100, 600000) end],
    fun([Id, Peso, Base, Inc, Ab, Ul]) ->
      case length(ids()) >= ?MAX_LOTES of
        true ->
          {error, {409, #{error => limite_de_lotes}}};
        false ->
          Cfg = #{id => Id, peso_kg => Peso, base_por_kg => Base,
                  incremento => Inc, abierto_ms => Ab, ultima_ms => Ul},
          case p65_lotes_sup:abrir(Cfg) of
            {ok, _} -> lote(id_bin(Id));
            {error, {already_started, _}} -> {error, {409, #{error => lote_ya_existe}}};
            {error, _} -> {error, {503, #{error => no_se_pudo_abrir}}}
          end
      end
    end).

pujar(IdBin, Body) ->
  case buscar(IdBin) of
    {ok, Id} ->
      maybe_ok(
        [fun() -> validar_postor(maps:get(<<"postor">>, Body, undefined)) end,
         fun() -> num(Body, <<"monto">>, undefined, 0.01, 1000000) end,
         fun() -> validar_canal(maps:get(<<"canal">>, Body, <<"remoto">>)) end],
        fun([Postor, Monto, Canal]) ->
          case catch p65_lote:pujar(Id, Postor, Monto, Canal) of
            {ok, Seq} ->
              {ok, #{seq => Seq, lote => info_map(safe_info(Id))}};
            {error, {puja_baja, Min}} ->
              {error, {409, #{error => puja_baja, minimo_por_kg => Min}}};
            {error, lote_cerrado} ->
              {error, {409, #{error => lote_cerrado}}};
            {error, lote_retirado} ->
              {error, {409, #{error => lote_retirado}}};
            {error, lote_inexistente} ->
              {error, {404, #{error => lote_inexistente}}};
            _ ->
              {error, {503, #{error => lote_no_disponible}}}
          end
        end);
    Error -> Error
  end.

retirar(IdBin) ->
  case buscar(IdBin) of
    {ok, Id} ->
      case catch p65_lote:retirar(Id) of
        ok -> lote(IdBin);
        {error, {no_permitido, Estado}} ->
          {error, {409, #{error => no_permitido, estado => Estado}}};
        _ -> {error, {503, #{error => lote_no_disponible}}}
      end;
    Error -> Error
  end.

%% ------------------------------------------------------------------
%% Bitacora (historial)
%% ------------------------------------------------------------------

eventos_de_lote(IdBin) ->
  case buscar(IdBin) of
    {ok, Id} -> {ok, [evento_map(E) || E <- p65_bitacora:eventos(Id)]};
    Error -> Error
  end.

ultimos(N) -> [evento_map(E) || E <- p65_bitacora:ultimos(N)].
desde(Seq, Limite) -> [evento_map(E) || E <- p65_bitacora:desde(Seq, Limite)].

evento_map({Seq, Lote, Tipo, Postor, Monto, Canal, Ts}) ->
  #{seq => Seq, lote => id_bin(Lote), tipo => Tipo, postor => nn(Postor),
    monto => Monto, canal => Canal, ts => Ts}.

%% ------------------------------------------------------------------
%% Metricas en formato de texto de Prometheus
%% ------------------------------------------------------------------

metricas() ->
  Infos = [I || Id <- ids(), I <- [safe_info(Id)], is_map(I)],
  Evs = p65_bitacora:todos(),
  Ahora = erlang:system_time(millisecond),
  Por = fun(Estado) -> length([x || #{estado := E} <- Infos, E =:= Estado]) end,
  %% Campos de la bitacora: {Seq, Lote, Tipo, Postor, Monto, Canal, Ts}
  Cuenta = fun(Tipo, Canal) ->
               length([x || {_, _, T, _, _, C, _} <- Evs, T =:= Tipo, C =:= Canal])
           end,
  Activos = length(lists:usort([P || {_, _, puja, P, _, _, Ts} <- Evs, Ahora - Ts < 60000])),
  PorLote = lists:foldl(fun({_, L, puja, _, _, _, _}, M) -> maps:update_with(L, fun(X) -> X + 1 end, 1, M);
                           (_, M) -> M end, #{}, Evs),
  Conteos = maps:values(PorLote),
  Adj = [I || #{estado := adjudicado, ganador := G} = I <- Infos, G =/= none],
  Ratios = [P / B || #{precio_por_kg := P, base_por_kg := B} <- Adj],
  Venta = lists:sum([T || #{total := T} <- Adj]),
  Lineas =
    [m("p65_lotes", "gauge", "Lotes por estado.",
       [{[{estado, E}], Por(E)} || E <- [abierto, ultima_llamada, adjudicado, retirado]]),
     m("p65_pujas_aceptadas_total", "counter", "Pujas aceptadas por canal.",
       [{[{canal, C}], Cuenta(puja, C)} || C <- [sala, remoto]]),
     m("p65_pujas_rechazadas_total", "counter", "Pujas rechazadas por canal.",
       [{[{canal, C}], Cuenta(puja_rechazada, C)} || C <- [sala, remoto]]),
     m("p65_participantes_activos", "gauge", "Postores con alguna puja en el ultimo minuto.",
       [{[], Activos}]),
     m("p65_pujas_por_lote_promedio", "gauge", "Pujas aceptadas por lote (lotes con pujas).",
       [{[], prom(Conteos)}]),
     m("p65_pujas_por_lote_maximo", "gauge", "Maximo de pujas aceptadas en un lote.",
       [{[], lists:max([0 | Conteos])}]),
     m("p65_precio_final_sobre_base", "gauge", "Precio final / base promedio de lotes adjudicados.",
       [{[], prom(Ratios)}]),
     m("p65_venta_total_pesos", "gauge", "Venta total de lotes adjudicados (MXN).",
       [{[], Venta}]),
     m("p65_beam_procesos", "gauge", "Procesos en la VM.",
       [{[], erlang:system_info(process_count)}]),
     m("p65_beam_memoria_bytes", "gauge", "Memoria total de la VM.",
       [{[], erlang:memory(total)}])],
  iolist_to_binary(Lineas).

prom([]) -> 0.0;
prom(L) -> lists:sum(L) / length(L).

m(Nombre, Tipo, Ayuda, Series) ->
  [io_lib:format("# HELP ~s ~s~n# TYPE ~s ~s~n", [Nombre, Ayuda, Nombre, Tipo]),
   [io_lib:format("~s~s ~s~n", [Nombre, labels(L), valor(V)]) || {L, V} <- Series]].

labels([]) -> "";
labels(L) ->
  [${, lists:join($,, [io_lib:format("~s=\"~s\"", [K, V]) || {K, V} <- L]), $}].

valor(V) when is_integer(V) -> integer_to_list(V);
valor(V) when is_float(V) -> float_to_list(V, [{decimals, 4}, compact]).

%% ------------------------------------------------------------------
%% Validacion
%% ------------------------------------------------------------------

safe_info(Id) ->
  case catch p65_lote:info(Id) of
    I when is_map(I) -> I;
    _ -> error
  end.

info_map(#{id := Id, ganador := G} = I) ->
  I#{id => id_bin(Id), ganador => nn(G)}.

nn(none) -> null;
nn(X) -> X.

maybe_ok(Pasos, Fin) ->
  recolectar(Pasos, [], Fin).

recolectar([], Acc, Fin) -> Fin(lists:reverse(Acc));
recolectar([P | R], Acc, Fin) ->
  case P() of
    {ok, V} -> recolectar(R, [V | Acc], Fin);
    {error, _} = E -> E
  end.

bad(Campo) -> {error, {400, #{error => campo_invalido, campo => Campo}}}.

validar_id(I) when is_integer(I), I > 0, I =< 999999999 -> {ok, I};
validar_id(B) when is_binary(B) ->
  case re:run(B, "^[A-Za-z0-9_-]{1,40}$", [{capture, none}]) of
    match -> {ok, B};
    nomatch -> bad(<<"id">>)
  end;
validar_id(_) -> bad(<<"id">>).

%% Numero entre Min y Max; si falta y hay valor por defecto, lo usa.
num(Body, Campo, Def, Min, Max) ->
  case maps:find(Campo, Body) of
    error when Def =/= undefined -> {ok, Def};
    error -> bad(Campo);
    {ok, N} when is_number(N), N >= Min, N =< Max -> {ok, N};
    {ok, _} -> bad(Campo)
  end.

validar_postor(B) when is_binary(B), byte_size(B) >= 1, byte_size(B) =< 64 ->
  case unicode:characters_to_list(B, utf8) of
    L when is_list(L) ->
      case lists:any(fun(C) -> C < 32 orelse C =:= 127 end, L) of
        true -> bad(<<"postor">>);
        false -> {ok, B}
      end;
    _ -> bad(<<"postor">>)
  end;
validar_postor(_) -> bad(<<"postor">>).

%% Solo dos valores permitidos; nunca se crean atomos desde la entrada del usuario.
validar_canal(<<"sala">>) -> {ok, sala};
validar_canal(<<"remoto">>) -> {ok, remoto};
validar_canal(_) -> bad(<<"canal">>).
