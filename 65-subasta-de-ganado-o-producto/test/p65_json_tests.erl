-module(p65_json_tests).
-include_lib("eunit/include/eunit.hrl").

ida_y_vuelta_test() ->
  M = #{<<"a">> => [1, 2.5, <<"hola">>, true, null], <<"b">> => #{<<"c">> => -3}},
  ?assertEqual({ok, M}, p65_json:decode(p65_json:encode(M))).

escapes_test() ->
  ?assertEqual(<<"\"a\\\"b\\n\"">>, p65_json:encode(<<"a\"b\n">>)),
  ?assertEqual({ok, <<"a\"b\n">>}, p65_json:decode(<<"\"a\\\"b\\n\"">>)),
  ?assertEqual({ok, <<"hóla"/utf8>>}, p65_json:decode(<<"\"h\\u00f3la\"">>)).

atomos_test() ->
  ?assertEqual(<<"\"abierto\"">>, p65_json:encode(abierto)),
  ?assertEqual(<<"null">>, p65_json:encode(null)).

numeros_test() ->
  ?assertEqual({ok, 12}, p65_json:decode(<<"12">>)),
  ?assertEqual({ok, 1.5}, p65_json:decode(<<"1.5">>)),
  ?assertEqual({ok, 100000.0}, p65_json:decode(<<"1e5">>)).

invalido_test_() ->
  [?_assertEqual({error, json_invalido}, p65_json:decode(X))
   || X <- [<<>>, <<"{bad">>, <<"[1,">>, <<"{\"a\":}">>, <<"[1] basura">>]].
