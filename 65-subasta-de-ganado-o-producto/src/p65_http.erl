%%% Arranque y parada del listener HTTP (Cowboy sobre Ranch).
-module(p65_http).

-export([iniciar/0, detener/0, dispatch/0]).

-define(APP, p65_subasta_de_ganado_o_producto).
-define(LISTENER, p65_http_listener).

dispatch() ->
  cowboy_router:compile([{'_', [
    {"/api/lotes", p65_api_handler, lotes},
    {"/api/lotes/:id", p65_api_handler, lote},
    {"/api/lotes/:id/pujas", p65_api_handler, pujas},
    {"/api/lotes/:id/retirar", p65_api_handler, retirar},
    {"/api/lotes/:id/eventos", p65_api_handler, eventos_lote},
    {"/api/eventos", p65_api_handler, eventos},
    {"/metrics", p65_api_handler, metrics},
    {"/ws/subasta", p65_ws_handler, []},
    %% La UI exportada de Google Stitch va en priv/www
    {"/", cowboy_static, {priv_file, ?APP, "www/index.html"}},
    {"/[...]", cowboy_static, {priv_dir, ?APP, "www"}}
  ]}]).

iniciar() ->
  Puerto = application:get_env(?APP, http_port, 8080),
  case cowboy:start_clear(?LISTENER, [{port, Puerto}],
                          #{env => #{dispatch => dispatch()}}) of
    {ok, _} ->
      logger:info("HTTP escuchando en el puerto ~p", [Puerto]),
      ok;
    {error, Razon} ->
      {error, {no_se_pudo_iniciar_http, Puerto, Razon}}
  end.

detener() ->
  _ = cowboy:stop_listener(?LISTENER),
  ok.
