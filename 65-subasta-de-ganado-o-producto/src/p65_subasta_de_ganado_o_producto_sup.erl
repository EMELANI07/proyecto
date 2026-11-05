-module(p65_subasta_de_ganado_o_producto_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% rest_for_one: la bitacora arranca primero; si cae, se reinician los lotes
%% (que dependen de ella para recuperar su estado) y el server.
init([]) ->
  Children = [
    %% Grupos de procesos (pg): los WebSockets se suscriben a 'p65_eventos'.
    %% Va primero y no depende de nadie, asi que sobrevive a caidas de la bitacora.
    #{id => pg, start => {pg, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    #{id => p65_bitacora, start => {p65_bitacora, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    #{id => p65_lotes_sup, start => {p65_lotes_sup, start_link, []},
      restart => permanent, shutdown => infinity, type => supervisor},
    #{id => p65_subasta_de_ganado_o_producto_server,
      start => {p65_subasta_de_ganado_o_producto_server, start_link, []},
      restart => permanent, shutdown => 5000, type => worker}
  ],
  {ok, {#{strategy => rest_for_one, intensity => 10, period => 60}, Children}}.
