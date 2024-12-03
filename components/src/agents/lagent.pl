% lagent.pl

% lightweight rli based agents

%% Agent@SimpleGoal: calls SimpleGoal using Agent's local Db
Agent@SimpleGoal:-
  adapt_agent_goal(Agent,SimpleGoal,NewGoal,Action),
  dispatch_agent_goal(Action,Agent,NewGoal).
  
dispatch_agent_goal(query,_Agent,Goal):-  
  call(Goal).
dispatch_agent_goal(update,Agent,Goal):-
  call(Goal),
  foreach(
    visiting(Agent,Host,Port),
    rli_call(Host,Port,(done:-Goal),_)
  ).  
  

%% Agent@[Super_1,...,Super_n]. Defines an Agent that inherits scripts form a list of Supers in the same space
   
adapt_agent_goal(A,G,NewG,Action):-nonvar(G),adapt_simple_goal(G,A,R,Action0),!,NewG=R,Action=Action0.
adapt_agent_goal(A,G,do_goal(A,G),query).

% it should be ok for a visitor to follow locals
%add_supers(A,_):-A==>'$visitor',!,errmes(cannot_create_agent,already_a_visitor(A)).
add_supers(A,Xs):-A<==follows(Xs).

%% is_agent(X): checks or bactracks over all agents in this space
is_agent(X):-gvar(X),X==>follows(Xs),nonvar(Xs).

adapt_simple_goal(init,A,add_supers(A,[]),query).
adapt_simple_goal([],A,add_supers(A,[]),query).
adapt_simple_goal([Super|Xs],A,add_supers(A,[Super|Xs]),query).

adapt_simple_goal(visit(H,P),A,visit(A,H,P),query).
adapt_simple_goal(visit(P),A,visit(A,P),query).

adapt_simple_goal(unvisit(H,P),A,unvisit(A,H,P),query).
adapt_simple_goal(unvisit(P),A,unvisit(A,P),query).

adapt_simple_goal(visiting(H,P),A,visiting(A,H,P),query).
adapt_simple_goal(visiting(P),A,visiting(A,P),query).

adapt_simple_goal((H:-B),A,db_assert(A,(H:-B)),update).
adapt_simple_goal(on_arrival(X),A,on_arrival(A,X),update).
adapt_simple_goal(assert(X),A,db_assert(A,X),update).
adapt_simple_goal(assertz(X),A,db_assertz(A,X),update).
adapt_simple_goal(asserta(X),A,db_asserta(A,X),update).
adapt_simple_goal(retract1(X),A,db_retract1(A,X),update).
adapt_simple_goal(retract(X),A,db_retract(A,X),update).
adapt_simple_goal(retractall(X),A,db_retractall(A,X),update).
adapt_simple_goal(abolish(X),A,db_abolish(A,X),update).
adapt_simple_goal(clear,A,db_clear(A),update).
adapt_simple_goal(consult(F),A,db_consult(F,A),update).
adapt_simple_goal(reconsult(F),A,db_reconsult(F,A),update).    

adapt_simple_goal(clause(H,B),A,db_clause(A,H,B),query).
adapt_simple_goal(self(H),A,do_goal(A,H),query).

adapt_simple_goal(listing,A,db_listing(A),query).

adapt_simple_goal(send_msg(To,Msg),A,send_msg(A,To,Msg),query).
adapt_simple_goal(handle_msg(From,Msg),A,handle_msg(From,A,Msg),query).

is_space(Port):-is_space(localhost,Port).

%% is_space(Host,Space): true if Space is registered at Host
is_space(Host,Port):-rli_registered(Host,Ps),member(Port,Ps).

%% start_space(Port): starts and registers locally an RLI service seen as associated to a space
start_space(Port):-start_space(localhost,localhost,Port).

%% start_space(BrokerHost,ThisHost,Port): starts an RLI service seen as associated to a space and registers it

start_space(_,_,Port):-
  '$space'==>OtherPort,
  !,
  errmes(no_space_started_at(Port),already_started_space(OtherPort)).
start_space(BrokerHost,ThisHost,Port):-
  '$space'<==Port,
  (BrokerHost==localhost->rli_start_broker;true),
  rli_wait(BrokerHost,broker),
  rli_start_server(Port),
  rli_wait(Port),
  rli_register(BrokerHost,ThisHost,Port).

get_space_name(Port):-'$space'==>Port.
  
unvisit(Agent,Port):-unvisit(Agent,localhost,Port).

%% unvisit(Agent,Host,Port): agent stops broadcasting its database update to Port
unvisit(Agent,Host,Port):-
  retract1('$visiting'(Agent,Host,Port)),
  rli_call(Host,Port,gvar_remove(Agent),_), % remove $visitor
  rli_call(Host,Port,db_clear(Agent),_).

on_arrival(Agent,Goal):-db_assert(Agent,on_arrival(Goal)).

%% waits until Agent visits - if var(Agent) waits until any agent visits
wait_for_agent(Agent):-repeat,sleep_ms(300),visitor(Agent),!.
    
visit(Agent,Port):-visit(Agent,localhost,Port).

%% visit(Agent,Host,Port): agent broadcasts its database and future updates to Port
visit(Agent,Host,Port):-
  visiting(Agent,Host,Port),
  !,
  errmes(no_reason_to_visit,already_visiting(Host,Port)).
visit(_Agent,Host,Port):-
  get_space_name(Port),
  Host==localhost,
  !,
  errmes(no_reason_to_visit,already_at(Port)).
visit(Agent,Host,Port):-
  rli_ping(Host,Port),
  assert('$visiting'(Agent,Host,Port)),
  rli_call(Host,Port,(done:-Agent<=='$visitor'),_),
  take_my_clauses(Agent,Host,Port).
  
take_my_clauses(Agent,Host,Port):-
  % todo - ensure indexing
  db_clause(Agent,H,B),
  rli_call(Host,Port,(done:-db_assert(Agent,(H:-B))),_),
  fail.
take_my_clauses(_Agent,_Host,_Port). 
 
visiting(Agent,Port):-visiting(Agent,localhost,Port).

%% visiting(Agent,Host,Port): iterates over Host,Port where the agent broadcasts its updates
visiting(Agent,Host,Port):-
  clause('$visiting'(Agent,Host,Port),true).

%% visitor(Agent): true if Agent has visited this space
visitor(Agent):-nonvar(Agent),!,Agent==>'$visitor'.
visitor(Agent):-gvar(Agent),Agent==>'$visitor'.
  
