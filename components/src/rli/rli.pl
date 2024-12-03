
/*
rli.pl

R(emote) L(ogic) I(nvocation) API

=======================================================================

The basic API is quite simple:

rli_in(Host,Port,Term): waits for a term to be posted on server at Host,Port

rli_out(Host,Port,Term): posts a Term on server at Host,Port - to be consumed
                         by the first rli_in waiting for it
                         


Note that "ports" are simply "names" that are "virtualized" by RMI. They can 
be integers or prolog atoms i.e. 9999 or 'snowflake' or 'Mary' qualify.
Think about them as "passwords" a client needs to know to access a server.
===========================================================================
*/

% tool interface

invoke_rli_method(MethodAndArgs,Result):-
  new_java_class('rli.RLIAdaptor',C),
  functor(MethodAndArgs,F,_),
  invoke_java_method(C,C,F,MethodAndArgs,Result).

%% rli_start_server(Port): starts RLI server on Port (which can be string name)
rli_start_server(Port):-
  \+(rli_ping(Port)),
  !,
  invoke_rli_method(rli_start_server(Port),InstanceId),
  instance_id<=InstanceId.
rli_start_server(Port):-
  errmes(rli_server_already_running,port(Port)).
  
%% rli_stop_server(Host,Port): stops RLI server at Host, Port
rli_stop_server(Host,Port):-
  rli_ping(Host,Port),
  rli_out0(Host,Port,stopping_server(Host,Port)),
  invoke_rli_method(rli_stop_server(Host,Port),_).

%% rli_in(Host,Port,Result): waits at Host Port until it can take out Result from there
rli_in(Host,Port,Result):-invoke_rli_method(rli_in(Host,Port),Result).

rli_out0(Host,Port,Term):-invoke_rli_method(rli_out(Host,Port,Term),_Result).

%% rli_out(Host,Port,Term): waits at Host,Port until it can place Term there
rli_out(Host,Port,Term):-nonvar(Host),nonvar(Port),!,
  rli_out0(Host,Port,the(Term)).
rli_out(Host,Port,Term):-
  errmes(nonvar_expected,rli_out(Host,Port,Term)).

rli_call(Host,Port,X,G,Answer):-rli_call(Host,Port,(X:-G),Answer).

%% rli_call(Host,Port,(AnswerPattern:-Goal),Answer): calls Host,Port with Goal and collects Answer
rli_call(Host,Port,Goal,Answer):-
  rli_call0(Host,Port,(R:-run_wrapped_goal(Goal,R)),Result),
  Result=the(X),
  nonvar(X),
  handle_rli_result(X,Host,Port,Answer).
  
rli_call0(Host,Port,Goal,Result):-invoke_rli_method(rli_call(Host,Port,Goal),Result).

handle_rli_result(first_answer(X),_,_,Answer):-Answer=the(X).
handle_rli_result(exception(E),Host,Port,_):-throw(remote_error_at(Host,Port,E)).
handle_rli_result(failed,_,_,no).

run_wrapped_goal((X:-G),R):-topcall(G),!,R=first_answer(X).
run_wrapped_goal(G,R):-topcall(G),!,R=first_answer(G).
run_wrapped_goal(_,failed).

%% rli_ping(Host,Port): succeeds only if a server exists at Host, Port
rli_ping(Host,Port):-invoke_rli_method(rli_ping(Host,Port),Result),Result>0.

%% rli_wait(Host,Port): block until a server exists at Host, Port
rli_wait(Host,Port):-
  repeat,
    for(I,1,10),
      Time is 10*I*I,
      sleep_ms(Time),
      rli_ping(Host,Port),
  !.

% rli_listen(Port): starts server and handler of incoming messages
rli_listen(Port):-
  rli_start_server(Port),
  rli_wait(Port),
  rli_start_handler(Port).

rli_start_handler(P):-rli_start_handler(localhost,P).

% rli_start_handler(H,P): starts rli_in handler that consumes and executs messages at Host,Port
rli_start_handler(H,P):-
  repeat,
    rli_in(H,P,Goal),
    ( Goal=the(Task)->
        call(Task),
      fail
    ; !,
      println(Goal)
    ).
    
% defaults

default_rli_port(well_known_server).

rli_listen:-default_rli_port(Port),rli_listen(Port).

rli_start_server:-default_rli_port(Port),rli_start_server(Port).

rli_start_handler:-default_rli_port(Port),rli_start_handler(Port).

rli_ping:-default_rli_port(Port),rli_ping(Port).

rli_wait:-default_rli_port(Port),rli_wait(Port).

rli_in(X):-default_rli_port(Port),rli_in(Port,X).

rli_out(X):-default_rli_port(Port),rli_out(Port,X).

rli_call(G,R):-default_rli_port(Port),rli_call(Port,G,R).

rli_stop_server:-default_rli_port(Port),rli_stop_server(Port).

% on localhost

rli_in(Port,Result):-rli_in(localhost,Port,Result).

rli_out(Port,Term):-rli_out(localhost,Port,Term).

rli_call(Port,Term,Res):-rli_call(localhost,Port,Term,Res).

rli_ping(Port):-rli_ping(localhost,Port).

rli_wait(Port):-rli_wait(localhost,Port).

rli_stop_server(Port):-rli_stop_server(localhost,Port).



% misc

/*
% discovers all available network interfaces on a computer
rli_get_inets(IAs):-
  %invoke_rli_method(rli_get_inets,Fun),
  call_java_class_method('rli.RLIAdaptor',rli_get_inets,Fun),
  Fun=..[_|IAs].
*/

%% rli_start_broker: starts rli broker on port 'broker', unless already running
rli_start_broker:-rli_ping(broker),!.
rli_start_broker:-rli_start_server(broker),index('$port_at'(1,1)),rli_wait(broker).


rli_register(ThisPort):-rli_register(localhost,localhost,ThisPort).

rli_unregister(ThisPort):-rli_unregister(localhost,localhost,ThisPort).

%% rli_register(Host,ThisHost,ThisPort): registers with broker at Host
rli_register(Host,ThisHost,ThisPort):-
  rli_call(Host,broker,register_port(ThisHost,ThisPort),_).

%% rli_unregister(Host,ThisHost,ThisPort): unregisters with broker at Host
rli_unregister(Host,ThisHost,ThisPort):-
  rli_call(Host,broker,unregister_port(ThisHost,ThisPort),_).

rli_registered(Ps):-rli_registered(localhost,Ps).

%% rli_registered(Host,HostPortPairs): retrieves HostPortPairs regustered with broker at Host
rli_registered(Host,Ps):-rli_call(Host,broker,(Ps:-registered_ports(Ps)),the(Ps)).
 
register_port(Host,Port):-topcall('$port_at'(Host,Port)),!.
register_port(Host,Port):-assert('$port_at'(Host,Port)).
  
unregister_port(Host,Port):-retract1('$port_at'(Host,Port)).
  
registered_ports(Ps):-findall(H-P,topcall('$port_at'(H,P)),Ps).



  
  