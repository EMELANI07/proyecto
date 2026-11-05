%%% Utilidades de prueba: detener un supervisor y esperar a que de verdad termine.
-module(p65_test_util).
-export([parar/1]).

parar(Pid) ->
  unlink(Pid),
  Ref = monitor(process, Pid),
  exit(Pid, shutdown),
  receive {'DOWN', Ref, _, _, _} -> ok
  after 5000 -> error(no_se_detuvo)
  end.
