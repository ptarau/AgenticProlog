% :-['agent_tests.pl'].

% broker operations

%% set_default_broker(Port): sets default broker to Port on localhost fort THIS process
set_default_broker(P):-set_default_broker(localhost,P).

%% set_default_broker(Host,Port): sets default broker for THIS process
set_default_broker(H,P):-
  broker_host<==H,
  broker_port<==P.
  
%% default_broker(H,P): returns host,port where the broker listens, override with broker_host<==..., broker_port<==...
default_broker(H,P):-
  broker_port==>P0,integer(P0),
  (broker_host==>H0;H0=localhost),
  !,
  H=H0,P=P0.
default_broker(localhost,5000).

%% ask_broker(Goal): runs Goal in the broker's process - calls directly if notices the broker is local - may start broker if absent
ask_broker(Goal):-isBroker==>yes,!,
  once(Goal).
ask_broker(Goal):-isBroker==>no,
  default_broker(H,P),
  s_ping(H,P),
  !,
  s_call(H,P,Goal,Goal,the(Goal)).
ask_broker(Goal):-
  default_broker(H,P),
  ( s_ping(H,P)->isBroker<==no,s_call(H,P,Goal,Goal,the(Goal))
  ; 
    isBroker<==yes,
    bg(s_server(P)),
    index(agent_info(1,0,0,0)),
    once(Goal)
  ).

%% start_broker: starts a broker in current process unless one is running on current host - therefore it never fails
start_broker:-ask_broker(true).

%% stop_broker: stops the broker running on this host - fails if no such broker runs

stop_broker:-
  default_broker(H,P),
  s_ping(H,P),
  ask_broker(clear_broker),
  s_stop(H,P),
  traceln(broker_stopped_at(H,P)),
  fail.
%stop_broker:-clear_broker,fail.
stop_broker.  

clear_broker:-  
   db_clear(broker),
   gvar_remove(isBroker),
   gvar_remove(new_port).


%% succeeds if there's a broker at default host:port
ping_broker:-default_broker(H,P),s_ping(H,P).

%% broker_state: - in the broker process prints out the state of the broker 
broker_state:-
  ((isBroker==>V)->println(isBroker==>V);println(this_is_not_a_broker)),
  ((new_port==>X)->println(new_port==>X);println(this_has_no_new_port)),
  default_broker(H,P),println(default_broker(H,P)),
  db_listing(broker),
  (s_ping(H,P)->Mes=broker_alive_at(H,P);Mes=no_broker_around),
  println(Mes).
     
% agent host/port assignment operations
 
agent_host(H):-agent_host==>H0,!,H=H0.
agent_host(localhost).
          
new_agent_port(Kind,Name,H, Port):-
  agent_host(H),
  ask_broker(assign_port(Kind,Name,H,Port0)),
  !,
  Port=Port0.
new_agent_port(_Kind,Name,_H, _Port):-
  errmes(other_agent_has_same_name,Name).
  
assign_port(_,Name,_,_):-
  db_clause(broker,agent_info(Name,_,_,_),true),
  !,
  fail.
assign_port(Kind,Name,H,Port):-
  new_port(P0),
  db_assert(broker,agent_info(Name,H,P0,Kind)),
  Port=P0.

get_last_port(P):-new_port==>P0,integer(P0),!,P=P0.
get_last_port(P):-default_broker(_,P).

make_new_agent_name(Name):-
  get_last_port(P),
  default_broker(_,P0),
  P1 is P-P0+1,
  atom_concat(agent,P1,Name).

new_port(P):-
  new_port==>P0,integer(P0),new_port_from(P0,P1),new_port<==P1,
  !,
  P=P1.
new_port(P):-
  default_broker(_,P0),
  new_port_from(P0,P1),new_port<==P1,
  !,
  P=P1.

new_port_from(OldPort,NewPort):-
  Base is OldPort+1,
  find_free_port(Base,1000,NewPort).
  
  
%% get_agent_info(Name,Host,Port,Kind): gets from the broker Host,Port,Kind info about named agent
get_agent_info(Name,Host,Port,Kind):-
  ask_broker(db_clause(broker,agent_info(Name,H,P,K),true)),
  !,
  Host=H,Port=P,Kind=K.

%% get_all_agents(Names): gets the list of all agents managed by this broker
get_all_agents(Names):-
  ask_broker(
    broker_get_all_agents(Names0)
  ),
  Names=Names0.

broker_get_all_agents(Names):-findall(Name,db_clause(broker,agent_info(Name,_,_,_),true),Names).

%% stop_all_agents: stops all agents and then stops the broker - the caller, if one of them, is a victim too
stop_all_agents:-
  ask_broker(bg(broker_kill_all_agents_then_die)),
  wait_for_no_broker.

wait_for_no_broker:- \+(ping_broker),!.
wait_for_no_broker:-sleep_ms(200),wait_for_no_broker.
  
broker_kill_all_agents_then_die:-
  broker_get_all_agents(Names),
  %traceln(Names),
  default_broker(H,P),
  s_wait(H,P),
 
  foreach(
    member(A,Names),
    stop_agent(A)
  ),
  %traceln(Names),
  broker_wait_no_agents_left(Names),
  stop_broker,
  fail.
  
broker_wait_no_agents_left(Names):-
  select(A,Names,LeftAlive),
  ( ping_agent(A)->sleep_ms(200),NewNames=[A|LeftAlive]
  ; traceln(agent_gone(A)),
    NewNames=LeftAlive
  ),
  !,
  broker_wait_no_agents_left(NewNames).
broker_wait_no_agents_left(_).
    
    
