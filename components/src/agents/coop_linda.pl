%% coop_linda.pl: lightweight cooperative engine coordinator using Linda operations

%% new_coordinator(Db): creates a new coordinator using database Db (or synthetic name if var)   
new_coordinator(Db):-
  db_ensure_bound(Db),
  db_dynamic(Db,available/1),
  db_dynamic(Db,waiting/2),
  db_dynamic(Db,running/1),
  index(waiting(1,0)),
  index(available(1)).

%% new_task(Coord,G): adds a new task to a coordinator Db    
new_task(Db,G):-
  new_engine(nothing,(G,fail),E),
  protect_engine(E),
  db_assertz(Db,running(E)).
  
/* and agent does this */

%% coop_in(T): waits until T is available - cooperative, requires a coordinator
coop_in(T):-return(in(T)),from_engine(X),T=X.

%% coop_out(T): makes T available - cooperative, requires a coordinator
coop_out(T):-return(out(T)).

%% coop_all(T,Ts): obtains the list Ts of all available terms matching T - cooperative, requires a coordinator
coop_all(T,Ts):-return(all(T,Ts)),from_engine(Ts).

/* coordinator does this */
handle_in(Db,T,E):-
  db_retract1(Db,available(T)),
  !,
  to_engine(E,T),
  db_assertz(Db,running(E)).
handle_in(Db,T,E):-
  db_assertz(Db,waiting(T,E)).
  
handle_out(Db,T):-
  db_retract1(Db,waiting(T,InE)),
  !,
  to_engine(InE,T),
  % this is the engine that was waiting for in/1
  db_assertz(Db,running(InE)).
handle_out(Db,T):-
  db_assertz(Db,available(T)).
  
handle_all(Db,T,Ts,E):-
  findall(T,db_clause(Db,available(T),true),Ts),
  to_engine(E,Ts),
  db_assertz(Db,running(E)).
 
% possible bug: if the engines are not protected
% and not on a heap - they can be claimed by symgc !!!

%% coordinate(Coordinator): coordinates a set of tascks performing coop_it/coop_out operations 
coordinate(Db):-
  repeat,
    ( db_retract1(Db,running(E))->
        get(E,the(A)),
        dispatch(A,Db,E),
        fail
     ; !
    ).

dispatch(in(X),Db,E):-handle_in(Db,X,E).
dispatch(out(X),Db,E):-handle_out(Db,X),db_assertz(Db,running(E)).
dispatch(all(T,Ts),Db,E):-handle_all(Db,T,Ts,E).
dispatch(exception(Ex),_,_):-throw(Ex).

%% stop_coordinator(C): stops a coordinator and cleans all realated resources - engines, unconsumed data etc.
stop_coordinator(C):-
  foreach(db_clause(C,running(E),true),stop(E)),
  foreach(db_clause(C,waiting(_,E),true),stop(E)),
  db_abolish(C,running/1),
  db_abolish(C,available/1),
  db_abolish(C,waiting/2).
  

/*
  
% possible alternative API

new_coordinator:-
  Db='$coop_linda',
  new_coordinator(Db),
  coordinator<=Db.

add_coop_agent(Name):-
  coordinator=>C,
  add_coop_agent(C,Name).

new_task(Goal):-
  coordinator=>C,
  new_task(C,Goal).

coordinate:-
  coordinator=>C,
  coordinate(C).

stop_coordinator:-
  coordinator=>C,
  stop_coordinator(C).
    
% also, use in/1 coop_out/1, coop_all/1 within tasks

% end of API
  
add_coop_agent(C,Name):-new_task(C,agent_loop(Name)).
  
agent_loop(Name):-
  coop_in(agent_task(Name,G)),
  ( call(G)->R=the(G)
  ; R=no
  ),
  coop_out(agent_result(Name,R)),
  agent_loop(Name).
  
set_goal(Name,G):-
  coop_out(agent_task(Name,G)),
  coop_in(agent_result(Name,R)),
  R=the(G).
   


% cooperative Linda - see more in xrun.pl       
test_loop_coordinator:-
  new_coordinator(C), % create scheduler
  
  add_coop_agent(C,alice), % declare agents
  add_coop_agent(C,bob),
  
  new_task(C,(
    set_goal(alice,X=1),  % declare tasks
    println(X),
    set_goal(bob,Y=2),
    println(Y)
  )),
  
  coordinate(C),  % run the tasks
  
  db_listing(C), % see final state
  stop_coordinator(C).
  
  
  
*/   