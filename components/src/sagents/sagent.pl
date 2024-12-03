%% file agent.pl: agent API

%% spawn_agent_group(Name,Agents): spawns a process controlled by agent Name, with each Agent on its thread
spawn_agent_group(Name,Agents):-
  spawn_agent(Name),
  ask_agent(Name,agent_group<==Agents),
  ask_agent(Name,maplist(new_agent,Agents)).

%% kill_agent_group(Name) : shuts down in a orderly manner all agents in the process controlled by Name
kill_agent_group(Name):-
   ask_agent(Name,agent_group==>Agents),
   ask_agent(Name,maplist(stop_agent,Agents)),
   kill_agent_process(Name).


spawn_with_broker(BrokerPort,AgentName):-
  spawn_with_broker(BrokerPort,AgentName,[]).

%% spawn_with_broker(BrokerPort,Name,Args): spawns new broker on given port and then gui Agent  
spawn_with_broker(BrokerPort,AgentName,AgentArgs):-
  spawn_with_broker(new_agent,BrokerPort,AgentName,AgentArgs).

%% spawn_quiet_agent_with_broker(BrokerPort,Name,Args): spawns new broker on given port and then service Agent
spawn_quiet_agent_with_broker(BrokerPort,AgentName,AgentArgs):-
  spawn_with_broker(new_s_agent,BrokerPort,AgentName,AgentArgs).

%% spawn_with_broker(AgentKind,BrokerPort,Name,Args): starts broker at BrokerPort and launches agent in separate process
spawn_with_broker(AgentKind,BrokerPort,AgentName,AgentArgs):-
  set_default_broker(BrokerPort),
  current_dir(D),
  spawn_agent(AgentKind,D,
    [ 
      set_default_broker(BrokerPort),
      start_broker
    ],
    AgentName,AgentArgs).

  
%% spawn_agent(Name): starts named agent in separate process in current directory
spawn_agent(Name):-spawn_agent(Name,[]).

%% spawn_agent(Name,AgentArgs): starts agent in new lprolog process than sends AgentArgs as separate commands to it
spawn_agent(Name,Args):-spawn_agent('.',[],Name,Args).

%% spawn_agent(Dir,ProcessArgs,Name,AgentArgs): starts agent in given Dir in new lprolog process - assumes lprolog script in PATH
spawn_agent(Dir,ProcessArgs0,Name,AgentArgs0):-
  spawn_agent(new_agent,Dir,ProcessArgs0,Name,AgentArgs0).

%% spawn_quiet_agent(Name): starts quiet agent with no window - assumes lprolog script in PATH
spawn_quiet_agent(Name):-spawn_quiet_agent('.',[],Name,[]).
  
%% spawn_quiet_agent(Dir,ProcessArgs,Name,AgentArgs): starts quiet agent with no window - assumes lprolog script in PATH - then runs AgentArgs
spawn_quiet_agent(Dir,ProcessArgs,Name,AgentArgs):-
  spawn_agent(new_s_agent,Dir,ProcessArgs,Name,AgentArgs).
  
spawn_agent(AgentKind,Dir,ProcessArgs0,Name,AgentArgs0):-
  start_broker,
  listify(ProcessArgs0,ProcessArgs),
  AgentStater=..[AgentKind,Name],
  append(ProcessArgs,[AgentStater],Cmds),
  bg((lprolog(Dir,Cmds,[aTRACE(running(Name))],Out),aTRACE(Out))),
  aTRACE(sending_process_cmd(Cmds)),
  wait_agent(Name),
  listify(AgentArgs0,AgentArgs),
  aTRACE(sending_goal_to(Name,AgentArgs)),
  maplist(ask_agent(Name),AgentArgs).
  
%% kill_agent_process(Name): kills process running and agent as well as all data related to it on the broker
kill_agent_process(Name):-ask_agent(Name,halt),fail.
kill_agent_process(Name):-clean_up_agent(Name).

%% agent_tracer: opens console at 6666 where debug messages with aTRACE can be seen - even of agents do no have consoles
agent_tracer:-bg(s_console(aTRACE,6666)).

%% stop_agent_trace: stop tracer
stop_agent_tracer:- stop_s_console(6666).

%% aTRACE(Mes): tries to write debug messages if agent_tracer is present if not locally
aTRACE(Mes):-self=>Agent,s_ping(6666),!,s_call(6666,writeln(Agent:Mes)).
aTRACE(Mes):-s_ping(6666),!,s_call(6666,writeln(aTRACE:Mes)).
aTRACE(Mes):-self=>Agent,!,writeln(Agent:Mes).
aTRACE(Mes):-writeln(aTRACE:Mes).



 
%% new_agent: creates an agent called agent0, agent1, ... in new GUI window that uses s_call+s_server 
new_agent:-ask_broker(make_new_agent_name(X)),new_agent(X).

%% new_agent(Name): creates an agent in new GUI window that uses s_call+s_server 
new_agent(Name):-new_gui_agent(Name).

%% new_s_agent(Name): creates an agent in new GUI window that uses s_call+s_server 
new_gui_agent(Name):-
  Kind=s_agent,
  new_agent_port(Kind,Name,H,P),
  bg(s_console(Name,P)),
  s_wait(H,P),
  set_agent_vars(Kind,Name,H,P).

%% new_s_agent(Name): creates an agent in current window that uses s_call+s_server - use stop_agent to stop it 
new_s_agent(Name):-
  Kind=s_agent,
  new_agent_port(Kind,Name,H,P),
  bg(s_server(P)),
  s_wait(H,P),
  set_agent_vars(Kind,Name,H,P).

%% new_m_agent(Name): creates an agent in current window using remote_run+run_server
new_m_agent(Name):-
  Kind=m_agent,
  new_agent_port(Kind,Name,H,P),
  bg(run_server(P)),
  remote_wait(H,P),
  set_agent_vars(Kind,Name,H,P).

set_agent_vars(Kind,Name,H,P):-ask_agent(Name,set_self(Kind,Name,H,P)).

set_self(Kind,Name,H,P):-self<=self(Kind,Name,H,P).

%% stop_agent(Name): stops agents - currently it only works if started with new_s_agent      
stop_agent(Name):-
  get_agent_info(Name,H,P,s_agent),
  clean_up_agent(Name),
  !,
  traceln(stoping(H,P)),
  stop_s_console(H,P),
  writeln(agent_stopped(Name,at(H,P))).
stop_agent(Name):-errmes(cannot_be_stopped,agent(Name)).  

clean_up_agent(Name):-
  ask_broker(db_retract1(broker,agent_info(Name,_,_,_))).
  
% agent operations

%% ask_agent(Name,Goal): asks named agent to run Goal
ask_agent(Name,Goal):-adapt_agent_goal(Name,Goal,G,_),ask_agent(Name,G,G,the(G)).

/*
% ask_agent(Name,X,G,R): asks named agent to run G computing X and returning R
ask_agent(Name,X,(A<=B),R):-!,force_ask_agent(Name,X,(A<=B),R).
ask_agent(Name,X,(A=>B),R):-!,force_ask_agent(Name,X,(A=>B),R).
ask_agent(Name,X,G,R):-Name=>s_agent,!,
  ( G->R=the(X)
  ; R=no
  ).
ask_agent(Name,X,G,R):-
 force_ask_agent(Name,X,G,R).
*/

% asks agent through communication layer - no direct call
ask_agent(Name,X,G,R):-
  get_agent_info(Name, H,P,Kind),
  ( Kind=s_agent->s_call(H,P,X,G,R0),check_if_exception(R0,Name,G,R)
  ; Kind=m_agent->remote_run(H,P,X,(set_self(Kind,Name,H,P),G),R)
  ; errmes(not_an_agent(Kind,Name),error_in(ask_agent(G)))
  ).
  
check_if_exception(exception,Name,G,_):-
  !,
  errmes(exception_in(ask_agent(Name)),goal=G). 
check_if_exception(R,_,_,R).

%% ping_agent(Name): succeeds is named agent is running
ping_agent(Name):-get_agent_info(Name,H,P,Kind),generic_ping(Kind,H,P).
 
generic_ping(s_agent,H,P):-s_ping(H,P).
generic_ping(m_agent,H,P):-remote_ping(H,P).
 
%% wait_agent(Name): waits until broker and named agent are running
wait_agent(Name):-
  default_broker(BH,BP),
  s_wait(BH,BP), % wait for a broker - but avoid starting one
  wait_for_agent_info(20,Name,H,P,Kind), % get info, then wait for actual agent
  generic_wait(Kind,H,P).

wait_for_agent_info(_,Name,H,P,K):-get_agent_info(Name,H,P,K),!.
wait_for_agent_info(Steps,Name,H,P,K):-Steps>0,!,
  Steps1 is Steps-1,
  sleep_ms(300),
  wait_for_agent_info(Steps1,Name,H,P,K).
 wait_for_agent_info(_,Name,_H,_P,_K):-
  errmes(timed_out,waiting_for_agent_inf(Name)).
  
generic_wait(s_agent,H,P):-s_wait(H,P).
generic_wait(m_agent,H,P):-remote_wait(H,P).
 
%% open_agent(Name,AgentConnection): open exclusive, efficient connection with agent, on which ask_agent is used
open_agent(Name,R):-
  get_agent_info(Name,H,P,s_agent),
  !,
  s_connection(H,P,Connection),
  R=agent_stream(Connection,Name).
open_agent(Name,_):-
  errmes(cannot_open_connection_to,agent(Name)).

%% close_agent(AgentConnection): closes exclusive, efficient connection with other agent
close_agent(agent_stream(Connection,_Name)):-s_disconnect(Connection).

%% s_run_at(AgentConnection,X,G,R): tells agent at Connection to run G returning the(X), no or exception
tell_agent_at(agent_stream(C,_),X,G,R):-generic_s_run_at(C,the(X,G),R).

%% tell_agent_at(AgentConnection,Goal): tells agent on the other side of Connection to run Goal
tell_agent_at(agent_stream(C,_),Goal):-s_run_at(C,Goal).

%% tell_agent_at(AgentConnection,SimpleGoal): tells AgentConnection to run SimpleGoal
tell_agent_at(agent_stream(C,Agent),Goal):-adapt_agent_goal(Agent,Goal,G,_),s_run_at(C,G).

%% Agent:SimpleGoal: asks Agent to run SimpleGoal - use agent_assert, agent_call for dynamic code local to the agent !!! 
Agent:SimpleGoal:-ask_agent(Agent,SimpleGoal).

%% agent_self(Info): if this symbol space is an agent, it returns Info=self(Kind,Name,Host,Port), fails otherwise.
agent_self(X):-self=>X0,!,X=X0.
agent_self(_):-errmes(error_in_agent_self,this_is_not_an_agent).

%% agent_name(Name): returns, to an agent, its own name, fails if not an agent
agent_name(Name):-agent_self(self(_K,Name,_H,_P_)).

%% agent_assert(X): when used as AgentName:agent_assert(X) asserts X into the local database of the agent
%% agent_assertz(X): with AgentName:... local db operation on the agent's space 
%% agent_asserta(X): with AgentName:... local db operation on the agent's space
%% agent_clause(H,B): with AgentName:... local db operation on the agent's space
%% agent_call(H): with AgentName:... local db operation on the agent's space
%% agent_retract1(X): with AgentName:... local db operation on the agent's space
%% agent_retract(X): with AgentName:... local db operation on the agent's space
%% agent_retractall(X): with AgentName:... local db operation on the agent's space
%% agent_abolish(X): with AgentName:... local db operation on the agent's space
%% agent_clear: AgentName:agent_clear clears the agent's local database
%% agent_listing: with AgentName:... local db operation on the agent's space
%% agent_consult(F): with AgentName:... local db operation on the agent's space
%% agent_reconsult(F): with AgentName:... local db operation on the agent's space

agent_assert(X):-agent_name(A),db_assert(A,X).
agent_assertz(X):-agent_name(A),db_assertz(A,X).
agent_asserta(X):-agent_name(A),db_asserta(A,X).
agent_clause(H,B):-agent_name(A),db_clause(A,H,B).
agent_call(H):-agent_name(A),do_goal(A,H).
agent_retract1(X):-agent_name(A),db_retract1(A,X).
agent_retract(X):-agent_name(A),db_retract(A,X).
agent_retractall(X):-agent_name(A),db_retractall(A,X).
agent_abolish(X):-agent_name(A),db_abolish(A,X).
agent_clear:-agent_name(A),db_clear(A).
agent_listing:-agent_name(A),db_listing(A).
agent_consult(F):-agent_name(A),db_consult(F,A).
agent_reconsult(F):-agent_name(A),db_reconsult(F,A).


 
