%%% WebSocket /ws/subasta: empuja cada evento de la bitacora al navegador.
%%% Se suscribe al grupo 'pg' p65_eventos; la bitacora le manda {evento, E}.
-module(p65_ws_handler).
-behaviour(cowboy_websocket).

-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2]).

init(Req, _) ->
  {cowboy_websocket, Req, #{}, #{idle_timeout => 60000, max_frame_size => 4096}}.

websocket_init(State) ->
  ok = pg:join(p65_eventos, self()),
  {[{text, p65_json:encode(#{tipo => hola, mensaje => <<"suscrito a la subasta en vivo">>})}],
   State}.

%% El cliente solo observa; "ping" sirve para mantener viva la conexion.
websocket_handle({text, <<"ping">>}, State) -> {[{text, <<"pong">>}], State};
websocket_handle(_, State) -> {[], State}.

websocket_info({evento, Ev}, State) ->
  {[{text, p65_json:encode(p65_api:evento_map(Ev))}], State};
websocket_info(_, State) ->
  {[], State}.
