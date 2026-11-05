-module(p65_subasta_de_ganado_o_producto_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  {ok, Sup} = p65_subasta_de_ganado_o_producto_sup:start_link(),
  case p65_http:iniciar() of
    ok -> {ok, Sup};
    {error, _} = Error -> Error
  end.

stop(_State) ->
  p65_http:detener().
