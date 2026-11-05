%%% JSON minimo (codificar y decodificar) para no depender de librerias extra.
%%% Mapas <-> objetos, listas <-> arreglos, binarios <-> cadenas.
%%% Los atomos true/false/null son literales; cualquier otro atomo se codifica
%%% como cadena (nunca se crean atomos al decodificar).
-module(p65_json).

-export([encode/1, decode/1]).

%% ---------------- Codificar ----------------

encode(Term) -> iolist_to_binary(enc(Term)).

enc(true) -> <<"true">>;
enc(false) -> <<"false">>;
enc(null) -> <<"null">>;
enc(undefined) -> <<"null">>;
enc(A) when is_atom(A) -> enc(atom_to_binary(A, utf8));
enc(B) when is_binary(B) -> [$", esc(B, <<>>), $"];
enc(I) when is_integer(I) -> integer_to_binary(I);
enc(F) when is_float(F) -> float_to_binary(F, [short]);
enc(M) when is_map(M) ->
  [${, lists:join($,, [[enc_key(K), $:, enc(V)] || {K, V} <- maps:to_list(M)]), $}];
enc(L) when is_list(L) ->
  [$[, lists:join($,, [enc(X) || X <- L]), $]].

enc_key(K) when is_atom(K) -> enc(atom_to_binary(K, utf8));
enc_key(K) when is_binary(K) -> enc(K);
enc_key(K) when is_integer(K) -> enc(integer_to_binary(K)).

esc(<<>>, Acc) -> Acc;
esc(<<$", R/binary>>, Acc) -> esc(R, <<Acc/binary, "\\\"">>);
esc(<<$\\, R/binary>>, Acc) -> esc(R, <<Acc/binary, "\\\\">>);
esc(<<$\n, R/binary>>, Acc) -> esc(R, <<Acc/binary, "\\n">>);
esc(<<$\r, R/binary>>, Acc) -> esc(R, <<Acc/binary, "\\r">>);
esc(<<$\t, R/binary>>, Acc) -> esc(R, <<Acc/binary, "\\t">>);
esc(<<C, R/binary>>, Acc) when C < 16#20 ->
  Hex = string:right(integer_to_list(C, 16), 4, $0),
  esc(R, <<Acc/binary, "\\u", (list_to_binary(Hex))/binary>>);
esc(<<C, R/binary>>, Acc) -> esc(R, <<Acc/binary, C>>).

%% ---------------- Decodificar ----------------

decode(Bin) when is_binary(Bin) ->
  try
    {V, Rest} = value(ws(Bin)),
    <<>> = ws(Rest),
    {ok, V}
  catch
    _:_ -> {error, json_invalido}
  end.

ws(<<C, R/binary>>) when C =:= $\s; C =:= $\t; C =:= $\n; C =:= $\r -> ws(R);
ws(B) -> B.

value(<<${, R/binary>>) -> object(ws(R), #{});
value(<<$[, R/binary>>) -> array(ws(R), []);
value(<<$", R/binary>>) -> string(R, <<>>);
value(<<"true", R/binary>>) -> {true, R};
value(<<"false", R/binary>>) -> {false, R};
value(<<"null", R/binary>>) -> {null, R};
value(B) -> number(B).

object(<<$}, R/binary>>, Acc) -> {Acc, R};
object(<<$", R/binary>>, Acc) ->
  {K, R1} = string(R, <<>>),
  <<$:, R2/binary>> = ws(R1),
  {V, R3} = value(ws(R2)),
  case ws(R3) of
    <<$,, R4/binary>> -> object(ws(R4), Acc#{K => V});
    <<$}, R4/binary>> -> {Acc#{K => V}, R4}
  end.

array(<<$], R/binary>>, Acc) -> {lists:reverse(Acc), R};
array(B, Acc) ->
  {V, R1} = value(B),
  case ws(R1) of
    <<$,, R2/binary>> -> array(ws(R2), [V | Acc]);
    <<$], R2/binary>> -> {lists:reverse([V | Acc]), R2}
  end.

string(<<$", R/binary>>, Acc) -> {Acc, R};
string(<<$\\, $", R/binary>>, Acc) -> string(R, <<Acc/binary, $">>);
string(<<$\\, $\\, R/binary>>, Acc) -> string(R, <<Acc/binary, $\\>>);
string(<<$\\, $/, R/binary>>, Acc) -> string(R, <<Acc/binary, $/>>);
string(<<$\\, $n, R/binary>>, Acc) -> string(R, <<Acc/binary, $\n>>);
string(<<$\\, $r, R/binary>>, Acc) -> string(R, <<Acc/binary, $\r>>);
string(<<$\\, $t, R/binary>>, Acc) -> string(R, <<Acc/binary, $\t>>);
string(<<$\\, $b, R/binary>>, Acc) -> string(R, <<Acc/binary, $\b>>);
string(<<$\\, $f, R/binary>>, Acc) -> string(R, <<Acc/binary, $\f>>);
string(<<$\\, $u, H:4/binary, R/binary>>, Acc) ->
  Cp = binary_to_integer(H, 16),
  case Cp of
    _ when Cp >= 16#D800, Cp =< 16#DBFF ->
      <<$\\, $u, L:4/binary, R2/binary>> = R,
      Lo = binary_to_integer(L, 16),
      Full = 16#10000 + ((Cp - 16#D800) bsl 10) + (Lo - 16#DC00),
      string(R2, <<Acc/binary, Full/utf8>>);
    _ ->
      string(R, <<Acc/binary, Cp/utf8>>)
  end;
string(<<C, R/binary>>, Acc) when C >= 16#20 -> string(R, <<Acc/binary, C>>).

number(B) ->
  {Num, Rest} = split_num(B, <<>>),
  {to_number(Num), Rest}.

split_num(<<C, R/binary>>, Acc)
  when (C >= $0 andalso C =< $9); C =:= $-; C =:= $+; C =:= $.; C =:= $e; C =:= $E ->
  split_num(R, <<Acc/binary, C>>);
split_num(R, Acc) -> {Acc, R}.

to_number(<<>>) -> error(vacio);
to_number(Num) ->
  try binary_to_integer(Num)
  catch error:badarg ->
    try binary_to_float(Num)
    catch error:badarg ->
      %% p. ej. "1e5" no es float valido para Erlang; "1.0e5" si
      [Mant, Exp] = binary:split(binary:replace(Num, <<"E">>, <<"e">>), <<"e">>),
      binary_to_float(<<Mant/binary, ".0e", Exp/binary>>)
    end
  end.
