%%% Handler HTTP unico para toda la API REST (el estado es el nombre de la ruta).
%%% Cowboy lanza un proceso por request: si este handler falla, solo muere ese.
-module(p65_api_handler).

-export([init/2]).

-define(MAX_BODY, 4096).

init(Req0, Ruta) ->
  Req = try
          atender(Ruta, cowboy_req:method(Req0), Req0)
        catch
          Clase:Razon:Stack ->
            logger:error("error en ~p: ~p:~p ~p", [Ruta, Clase, Razon, Stack]),
            responder(500, #{error => error_interno}, Req0)
        end,
  {ok, Req, Ruta}.

%% ---- Rutas ----
atender(_, <<"OPTIONS">>, Req) ->
  cowboy_req:reply(204, cabeceras(<<"text/plain">>), Req);

atender(lotes, <<"GET">>, Req) ->
  responder(200, #{lotes => p65_api:lotes()}, Req);
atender(lotes, <<"POST">>, Req0) ->
  con_json(Req0, fun(Body, Req) ->
    resultado(201, p65_api:crear(Body), Req)
  end);

atender(lote, <<"GET">>, Req) ->
  resultado(200, p65_api:lote(cowboy_req:binding(id, Req)), Req);

atender(pujas, <<"POST">>, Req0) ->
  con_json(Req0, fun(Body, Req) ->
    resultado(201, p65_api:pujar(cowboy_req:binding(id, Req), Body), Req)
  end);

atender(retirar, <<"POST">>, Req) ->
  resultado(200, p65_api:retirar(cowboy_req:binding(id, Req)), Req);

atender(eventos_lote, <<"GET">>, Req) ->
  case p65_api:eventos_de_lote(cowboy_req:binding(id, Req)) of
    {ok, Evs} -> responder(200, #{eventos => Evs}, Req);
    {error, {Cod, Map}} -> responder(Cod, Map, Req)
  end;

%% GET /api/eventos?ultimos=50   -> los ultimos N (maximo 500)
%% GET /api/eventos?desde=123    -> los posteriores a la secuencia 123 (maximo 500)
atender(eventos, <<"GET">>, Req) ->
  Qs = cowboy_req:parse_qs(Req),
  Evs = case {entero(<<"desde">>, Qs), entero(<<"ultimos">>, Qs)} of
          {Desde, _} when is_integer(Desde) -> p65_api:desde(Desde, 500);
          {_, N} when is_integer(N) -> p65_api:ultimos(min(max(N, 1), 500));
          _ -> p65_api:ultimos(50)
        end,
  responder(200, #{eventos => Evs}, Req);

atender(metrics, <<"GET">>, Req) ->
  cowboy_req:reply(200, cabeceras(<<"text/plain; version=0.0.4; charset=utf-8">>),
                   p65_api:metricas(), Req);

atender(_, _, Req) ->
  responder(405, #{error => metodo_no_permitido}, Req).

%% ---- Auxiliares ----
con_json(Req0, Fun) ->
  %% Se rechaza por content-length antes de leer; y se vuelve a comprobar el tamano real.
  case cowboy_req:body_length(Req0) of
    Largo when is_integer(Largo), Largo > ?MAX_BODY ->
      responder_cerrando(413, #{error => cuerpo_demasiado_grande}, Req0);
    _ ->
      case cowboy_req:read_body(Req0, #{length => ?MAX_BODY}) of
        {ok, Data, Req} when byte_size(Data) =< ?MAX_BODY ->
          case p65_json:decode(Data) of
            {ok, Body} when is_map(Body) -> Fun(Body, Req);
            _ -> responder(400, #{error => json_invalido}, Req)
          end;
        {ok, _, Req} ->
          responder_cerrando(413, #{error => cuerpo_demasiado_grande}, Req);
        {more, _, Req} ->
          responder_cerrando(413, #{error => cuerpo_demasiado_grande}, Req)
      end
  end.

resultado(CodOk, {ok, Datos}, Req) -> responder(CodOk, Datos, Req);
resultado(_, {error, {Cod, Map}}, Req) -> responder(Cod, Map, Req).

responder(Codigo, Mapa, Req) ->
  cowboy_req:reply(Codigo, cabeceras(<<"application/json; charset=utf-8">>),
                   p65_json:encode(Mapa), Req).

%% Con un cuerpo sin leer, el servidor cierra el socket: se avisa al cliente
%% para que no intente reutilizar la conexion.
responder_cerrando(Codigo, Mapa, Req) ->
  Cab = (cabeceras(<<"application/json; charset=utf-8">>))#{<<"connection">> => <<"close">>},
  cowboy_req:reply(Codigo, Cab, p65_json:encode(Mapa), Req).

cabeceras(Tipo) ->
  #{<<"content-type">> => Tipo,
    <<"cache-control">> => <<"no-store">>,
    <<"access-control-allow-origin">> => <<"*">>,
    <<"access-control-allow-methods">> => <<"GET, POST, OPTIONS">>,
    <<"access-control-allow-headers">> => <<"content-type">>}.

entero(Clave, Qs) ->
  case lists:keyfind(Clave, 1, Qs) of
    {_, V} ->
      try binary_to_integer(V) catch error:badarg -> undefined end;
    false -> undefined
  end.
