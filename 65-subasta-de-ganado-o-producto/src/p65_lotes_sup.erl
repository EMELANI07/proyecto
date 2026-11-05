-module(p65_lotes_sup).
-behaviour(supervisor).

-export([start_link/0, abrir/1]).
-export([init/1]).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

abrir(Cfg) -> supervisor:start_child(?MODULE, [Cfg]).

init([]) ->
  Hijo = #{id => p65_lote, start => {p65_lote, start_link, []},
           restart => transient, shutdown => 5000, type => worker},
  {ok, {#{strategy => simple_one_for_one, intensity => 10, period => 60}, [Hijo]}}.
