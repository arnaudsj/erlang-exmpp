%% Copyright ProcessOne 2006-2010. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.

%% @author Will Glozer <will@glozer.net>

%% @doc
%% The module <strong>{@module}</strong> manages SSL socket
%% connections to an XMPP server.
%%
%% <p>
%% This module is intended to be used directly by client developers.
%% </p>

-module(exmpp_ssl).


-export([connect/3, send/2, close/2, reset_parser/1]).


%% -- client interface --


%% Internal export
-export([receiver/4]).

reset_parser(ReceiverPid) when is_pid(ReceiverPid) ->
    ReceiverPid ! reset_parser.

%% Connect to XMPP server
%% Returns:
%% Ref or throw error
%% Ref is a socket
connect(ClientPid, StreamRef, {Host, Port}) ->
    DefaultOptions = [{packet,0}, binary, {active, once}],
    {SetOptsModule,Opts} =
	case check_new_ssl() of
	    true ->  {inet,[{reuseaddr,true}|DefaultOptions]};
	    false -> {ssl,DefaultOptions}
	end,
    case ssl:connect(Host, Port, Opts, 30000) of
	{ok, Socket} ->
	    %% TODO: Hide receiver failures in API
	    ReceiverPid = spawn_link(?MODULE, receiver,
				     [ClientPid, Socket,SetOptsModule, StreamRef]),
	    ssl:controlling_process(Socket, ReceiverPid),
	    {Socket, ReceiverPid};
	{error, Reason} ->
	    erlang:throw({socket_error, Reason})
    end.
%% if we use active-once before spawning the receiver process,
%% we can receive some data in the original process rather than
%% in the receiver process. So {active.once} is is set explicitly
%% in the receiver process. NOTE: in this case this wouldn't make
%% a big difference, as the connecting client should send the
%% stream header before receiving anything


close(Socket, ReceiverPid) ->
    ReceiverPid ! stop,
    ssl:close(Socket).

send(Socket, XMLPacket) ->
    %% TODO: document_to_binary to reduce memory consumption
    String = exmpp_xml:document_to_list(XMLPacket),
    case ssl:send(Socket, String) of
	ok -> ok;
	_Other -> {error, send_failed}
    end.

%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------
receiver(ClientPid, Socket,SetOptsModule, StreamRef) ->
    receiver_loop(ClientPid, Socket,SetOptsModule, StreamRef).

receiver_loop(ClientPid, Socket,SetOptsModule, StreamRef) ->
    SetOptsModule:setopts(Socket, [{active, once}]),
    receive
	stop ->
	    ok;
	{ssl, Socket, Data} ->
	    {ok, NewStreamRef} = exmpp_xmlstream:parse(StreamRef, Data),
	    receiver_loop(ClientPid, Socket,SetOptsModule, NewStreamRef);
	{ssl_closed, Socket} ->
	    gen_fsm:send_all_state_event(ClientPid, tcp_closed);
	{ssl_error,Socket,Reason} ->
	    error_logger:warning_msg([ssl_error,{ssl_socket,Socket},Reason]),
	    gen_fsm:send_all_state_event(ClientPid, tcp_closed);
    reset_parser ->
        receiver_loop(ClientPid, Socket, SetOptsModule, exmpp_xmlstream:reset(StreamRef))
    end.


%% In R12, inet:setopts/2 doesn't accept the new ssl sockets
check_new_ssl() ->
    case erlang:system_info(version) of
        [$5,$.,Maj] when Maj < $6  ->
            false;
        [$5,$.,Maj, $.,_Min] when ( Maj < $6 ) ->
            false;
        _  ->
            true
    end.
