%%%-------------------------------------------------------------------
%% @doc UniCom public API
%% @end
%%%-------------------------------------------------------------------

-module(unicom_app).

-behaviour(application).

-export([start/2, stop/1]).

-include("unicom.hrl").

start(_StartType, _StartArgs) ->
	case mnesia:create_schema([node()]) of
		ok -> ok;
		{error, {_, {already_exists, _}}} -> ok
	end,
	mnesia:start(),

	
	case mnesia:create_table(user, [
		{attributes, record_info(fields, user)},
		{ram_copies, [node()]}
	]) of
		{atomic, ok} -> ok;
		{aborted, {already_exists, user}} -> ok
	end,

	Dispatch = cowboy_router:compile([
					  {'_',[
						{"/ws", unicom_ws_handler, []}
					       ]}
					 ]),
	{ok, _} = cowboy:start_clear(
		    unicom_http_listener,
		    [{port, 8080}],
		    #{env => #{dispatch => Dispatch}}
		   ),
    unicom_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
