%%% Pruebas de integracion: arranca la aplicacion completa (con Cowboy) en un puerto
%%% de prueba y le habla por HTTP real.
-module(p65_api_tests).
-include_lib("eunit/include/eunit.hrl").

-define(APP, p65_subasta_de_ganado_o_producto).
-define(PUERTO, 18080).

api_test_() ->
  {setup,
   fun() ->
     _ = application:load(?APP),
     ok = application:set_env(?APP, http_port, ?PUERTO),
     {ok, _} = application:ensure_all_started(?APP),
     {ok, _} = application:ensure_all_started(inets),
     ok
   end,
   fun(_) -> ok = application:stop(?APP) end,
   {timeout, 60,
    [fun crear_y_pujar/0,
     fun validaciones/0,
     fun cierre_y_retiro/0,
     fun difusion_en_vivo/0,
     fun metricas/0,
     fun estaticos/0]}}.

crear_y_pujar() ->
  {201, L} = enviar("/api/lotes", #{id => 501, peso_kg => 200, base_por_kg => 50,
                                   abierto_ms => 5000}),
  ?assertEqual(<<"abierto">>, maps:get(<<"estado">>, L)),
  ?assertEqual(null, maps:get(<<"ganador">>, L)),
  ?assertMatch({409, #{<<"error">> := <<"lote_ya_existe">>}},
               enviar("/api/lotes", #{id => 501, peso_kg => 200, base_por_kg => 50})),
  {201, R} = enviar("/api/lotes/501/pujas", #{postor => <<"Ana">>, monto => 55, canal => <<"sala">>}),
  ?assertEqual(<<"Ana">>, maps:get(<<"ganador">>, maps:get(<<"lote">>, R))),
  %% puja baja: se rechaza y se informa el minimo
  ?assertMatch({409, #{<<"error">> := <<"puja_baja">>, <<"minimo_por_kg">> := 56}},
               enviar("/api/lotes/501/pujas", #{postor => <<"Beto">>, monto => 55})),
  ?assertMatch({404, #{<<"error">> := <<"lote_inexistente">>}},
               enviar("/api/lotes/9999/pujas", #{postor => <<"Ana">>, monto => 60})),
  {200, #{<<"eventos">> := Evs}} = pedir("/api/lotes/501/eventos"),
  ?assertEqual([<<"abre">>, <<"puja">>, <<"puja_rechazada">>],
               [maps:get(<<"tipo">>, E) || E <- Evs]),
  {200, #{<<"lotes">> := Lotes}} = pedir("/api/lotes"),
  ?assert(lists:any(fun(X) -> maps:get(<<"id">>, X) =:= <<"501">> end, Lotes)).

validaciones() ->
  ?assertMatch({400, #{<<"error">> := <<"json_invalido">>}}, enviar_raw("/api/lotes", <<"no es json">>)),
  ?assertMatch({400, #{<<"campo">> := <<"id">>}}, enviar("/api/lotes", #{id => <<"x y">>, peso_kg => 1, base_por_kg => 1})),
  ?assertMatch({400, #{<<"campo">> := <<"peso_kg">>}}, enviar("/api/lotes", #{id => 502, peso_kg => -1, base_por_kg => 1})),
  ?assertMatch({400, #{<<"campo">> := <<"canal">>}},
               enviar("/api/lotes/501/pujas", #{postor => <<"Ana">>, monto => 99, canal => <<"hacker">>})),
  ?assertMatch({400, #{<<"campo">> := <<"postor">>}},
               enviar("/api/lotes/501/pujas", #{postor => <<>>, monto => 99})),
  ?assertMatch({413, _}, enviar_raw("/api/lotes", binary:copy(<<"a">>, 6000))),
  ?assertMatch({405, _}, request(delete, "/api/lotes", undefined)).

cierre_y_retiro() ->
  {201, _} = enviar("/api/lotes", #{id => 503, peso_kg => 100, base_por_kg => 40,
                                   abierto_ms => 100, ultima_ms => 100}),
  {201, _} = enviar("/api/lotes/503/pujas", #{postor => <<"Ana">>, monto => 41}),
  timer:sleep(500),
  {200, L} = pedir("/api/lotes/503"),
  ?assertEqual(<<"adjudicado">>, maps:get(<<"estado">>, L)),
  %% puja que llega despues del martillazo
  ?assertMatch({409, #{<<"error">> := <<"lote_cerrado">>}},
               enviar("/api/lotes/503/pujas", #{postor => <<"Tardio">>, monto => 999})),
  %% retirar un lote abierto
  {201, _} = enviar("/api/lotes", #{id => 504, peso_kg => 100, base_por_kg => 40}),
  ?assertMatch({200, #{<<"estado">> := <<"retirado">>}}, enviar("/api/lotes/504/retirar", #{})),
  ?assertMatch({409, #{<<"error">> := <<"lote_retirado">>}},
               enviar("/api/lotes/504/pujas", #{postor => <<"Ana">>, monto => 99})),
  ?assertMatch({409, #{<<"error">> := <<"no_permitido">>}}, enviar("/api/lotes/503/retirar", #{})).

%% Lo que recibe un WebSocket: cada evento de la bitacora llega a los suscritos a pg.
difusion_en_vivo() ->
  ok = pg:join(p65_eventos, self()),
  {201, _} = enviar("/api/lotes", #{id => 505, peso_kg => 100, base_por_kg => 40, abierto_ms => 5000}),
  {201, _} = enviar("/api/lotes/505/pujas", #{postor => <<"Ana">>, monto => 45}),
  ?assertMatch({evento, {_, 505, abre, none, 40, sistema, _}}, esperar_evento()),
  ?assertMatch({evento, {_, 505, puja, <<"Ana">>, 45, remoto, _}}, esperar_evento()),
  ok = pg:leave(p65_eventos, self()).

esperar_evento() ->
  receive {evento, _} = E -> E after 2000 -> sin_evento end.

metricas() ->
  {200, Texto} = request(get, "/metrics", undefined),
  ?assertNotEqual(nomatch, binary:match(Texto, <<"p65_lotes{estado=\"abierto\"}">>)),
  ?assertNotEqual(nomatch, binary:match(Texto, <<"p65_pujas_aceptadas_total{canal=\"sala\"}">>)).

estaticos() ->
  {200, Html} = request(get, "/", undefined),
  ?assertNotEqual(nomatch, binary:match(Html, <<"Subasta">>)),
  ?assertMatch({404, _}, request(get, "/no_existe.js", undefined)).

%% ---- Cliente HTTP minimo ----
pedir(Ruta) -> decodificar(request(get, Ruta, undefined)).
enviar(Ruta, Mapa) -> decodificar(request(post, Ruta, p65_json:encode(Mapa))).
enviar_raw(Ruta, Cuerpo) -> decodificar(request(post, Ruta, Cuerpo)).

decodificar({Cod, Cuerpo}) ->
  case p65_json:decode(Cuerpo) of
    {ok, Mapa} -> {Cod, Mapa};
    _ -> {Cod, Cuerpo}
  end.

request(Metodo, Ruta, Cuerpo) ->
  Url = "http://localhost:" ++ integer_to_list(?PUERTO) ++ Ruta,
  Req = case Cuerpo of
          undefined -> {Url, []};
          _ -> {Url, [], "application/json", Cuerpo}
        end,
  {ok, {{_, Cod, _}, _, Resp}} = httpc:request(Metodo, Req, [], [{body_format, binary}]),
  {Cod, Resp}.
