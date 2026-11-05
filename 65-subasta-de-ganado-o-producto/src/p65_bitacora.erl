-module(p65_bitacora).
-behaviour(gen_server).

-export([start_link/0, registrar/5, eventos/1, todos/0, ultimos/1, desde/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(TAB, p65_bitacora_tab).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Tipo: abre | puja | puja_rechazada | adjudicado | retirado
registrar(Lote, Tipo, Postor, Monto, Canal) ->
  gen_server:call(?MODULE, {registrar, Lote, Tipo, Postor, Monto, Canal}).

%% Eventos de un lote en orden de llegada (ordered_set por secuencia)
eventos(Lote) ->
  ets:match_object(?TAB, {'_', Lote, '_', '_', '_', '_', '_'}).

%% Toda la bitacora en orden de secuencia (la usa el simulador para auditar)
todos() ->
  ets:tab2list(?TAB).

%% Los ultimos N eventos, en orden ascendente
ultimos(N) ->
  ultimos(ets:last(?TAB), N, []).

ultimos('$end_of_table', _, Acc) -> Acc;
ultimos(_, 0, Acc) -> Acc;
ultimos(Seq, N, Acc) ->
  [E] = ets:lookup(?TAB, Seq),
  ultimos(ets:prev(?TAB, Seq), N - 1, [E | Acc]).

%% Eventos con secuencia mayor a Seq (hasta Limite), en orden ascendente
desde(Seq, Limite) ->
  case ets:select(?TAB, [{{'$1', '_', '_', '_', '_', '_', '_'}, [{'>', '$1', Seq}], ['$_']}],
                  Limite) of
    {Evs, _Cont} -> Evs;
    '$end_of_table' -> []
  end.

init([]) ->
  ets:new(?TAB, [ordered_set, named_table, protected]),
  {ok, 0}.

handle_call({registrar, Lote, Tipo, Postor, Monto, Canal}, _From, Seq0) ->
  Seq = Seq0 + 1,
  Ts = erlang:system_time(millisecond),
  Ev = {Seq, Lote, Tipo, Postor, Monto, Canal, Ts},
  true = ets:insert(?TAB, Ev),
  %% Difusion en vivo a los WebSockets suscritos (grupo 'pg' p65_eventos)
  [Pid ! {evento, Ev} || Pid <- pg:get_members(p65_eventos)],
  {reply, {ok, Seq}, Seq}.

handle_cast(_Msg, S) -> {noreply, S}.
handle_info(_Info, S) -> {noreply, S}.
