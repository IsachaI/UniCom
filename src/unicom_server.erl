-module(unicom_server).
-export([start_link/0, init/0]).
-include("unicom.hrl").

start_link() -> 
	Pid = spawn_link(?MODULE, init, []), %new linked process with current module name with empty user list
	register(unicom_server, Pid), 
	{ok, Pid}.

init() ->
	loop().

loop() ->
	receive
		{From, logon, Name} ->
			server_logon(From, Name),
			loop();
		{From, logoff} ->
			server_logoff(From),
			loop();
		{From, message_to, To, Message} ->
			server_transfer(From, To, Message),
			loop()
	end.


server_logon(From, Name) ->
	F = fun() ->
		case mnesia:read({user, Name}) of
		     [] ->	%check if user already exist
				mnesia:write(#user{name = Name, pid = From}),
				logged_on;
			[_Existing] ->
				user_already_exists
		end
	    end,
	case mnesia:transaction(F) of
		{atomic, logged_on} -> 
			From ! {server, logged_on};
		{atomic, user_already_exists} ->
			From ! {server, stop, user_already_exists}
	end.




server_logoff(From) ->
	F = fun() ->
		case mnesia:match_object(#user{name = '_', pid = From}) of
			[#user{name = Name}]  ->
				mnesia:delete({user, Name}),
				logged_off;
			[] ->
				not_found
		end
	    end,
	case mnesia:transaction(F) of
		{atomic, logged_off} -> ok;
		{atomic, not_found} -> ok
	end.


server_transfer(From, To, Message) ->
	F =  fun() ->
		case mnesia:match_object(#user{name = '_', pid = From}) of
			[] ->
				not_logged_on;
			[#user{name = Name}] ->
				case mnesia:read({user, To}) of 
					[] ->
						receiver_not_found;
					[#user{pid = ToPid}] -> 
						ToPid ! {message_from, Name, Message},
						sent
				end
		end
	    end,
	case mnesia:transaction(F) of 
		{atomic, not_logged_on} -> 
			From ! {server, stop, not_logged_on};
		{atomic, receiver_not_fouind} ->
			From ! {server, receiver_not_found};
		{atomic, sent} ->
			From ! {server, sent}
	end.

	
