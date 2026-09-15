-module(unicom_ws_handler).
-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2, terminate/3]).

init(Req, State) ->
	{cowboy_websocket, Req, State}.

websocket_init(_State) ->
	{ok, undefined}.


websocket_handle({text, Data}, State) ->
	Decoded = json:decode(Data),
	case Decoded of
		#{<<"action">> := <<"logon">>, <<"name">> := NameBin} ->
			Name = binary_to_atom(NameBin, utf8),
			unicom_server ! {self(), logon, Name},
			{ok, Name};
		#{<<"action">> := <<"message">>, <<"to">> := ToBin, <<"text">>:= Text} ->
			To = binary_to_atom(ToBin, utf8),
			unicom_server ! {self(), message_to, To, Text},
			{ok, State};
		_->
			{ok, State}
	end;

websocket_handle(_Frame, State) ->
	{ok, State}.


%%CALLBACK FUNCTIONS MATCH SERVER CALL
%%
%%
%%
websocket_info({server, logged_on}, State) ->
	{reply, {text, json:encode(#{type => <<"logged_on">>})}, State};

websocket_info({server, stop, Reason}, State) ->
    Json = json:encode(#{type => <<"error">>, reason => atom_to_binary(Reason, utf8)}),
    {reply, {text, Json}, State};

websocket_info({server, sent}, State) ->
    {reply, {text, json:encode(#{type => <<"sent">>})}, State};

websocket_info({server, receiver_not_found}, State) ->
    {reply, {text, json:encode(#{type => <<"receiver_not_found">>})}, State};

websocket_info({message_from, Name, Message}, State) ->
    Json = json:encode(#{
        type => <<"message">>,
        from => atom_to_binary(Name, utf8),
        text => Message
    }),
    {reply, {text, Json}, State};

websocket_info(_Info, State) ->
    {ok, State}.

terminate(_Reason, _Req, State) ->
	case State of 
		undefined -> ok;
		_Name -> unicom_server ! {self(), logoff}
	end,
	ok.
