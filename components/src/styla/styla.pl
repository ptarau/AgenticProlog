% Styla interface

%% new_styla_engine(E): creates a new Styla engine E
new_styla_engine(E):-
  call_java_class_method('styla.Inter',new_styla_engine,E).

%% styla_engine_set_goal(E,A,G): sets goal term G and answer pattern A for E  
styla_engine_set_goal(E,A,G):-
  call_java_class_method('styla.Inter',styla_engine_set_goal(E,A,G),_).

%% styla_engine_set_goal_string(E,G): sets string G to be parsed as goal for E  
styla_engine_set_goal_string(E,G):-
  call_java_class_method('styla.Inter',styla_engine_set_goal_string(E,G),_). 
  
%% ask_styla_engine(E,R): asks Styla engine E and returns answer term R
ask_styla_engine(E,R):-
  call_java_class_method('styla.Inter',ask_styla_engine(E),R).
  
%% stop_styla_engine(E): stops Styla engine E 
stop_styla_engine(E):-
  call_java_class_method('styla.Inter',stop_styla_engine(E),_).

%% default_styla_engine(E): the default Styla engine E e.g. in which asserts persist
default_styla_engine(E):-gvar_get(styla_engine,X),!,E=X.
default_styla_engine(E):-new_styla_engine(E),gvar_set(styla_engine,E).

%% styla_once(X,G,R): calls goal G and applies Styla's bindings to G
styla_once(G):-styla_once(G,G,G).

%% styla_once(X,G,R): collects first Styla answer from E running goal G 
styla_once(X,G,R):-
  default_styla_engine(E),
  styla_engine_set_goal(E,X,G),
  ask_styla_engine(E,R),
  stop_styla_engine(E).

%% styla_once(X,G,R): collects all Styla answers from E running goal G 
styla_all(X,G,Xs):-styla_once(findall(X,G,Xs)).
    
styla_test(A,G,R):-
  new_styla_engine(E),
  println(e=E),
  styla_engine_set_goal(E,A,G),
  println(goal_set),
  ask_styla_engine(E,R),
  %println(answer=R),
  stop_styla_engine(E),
  println(engine_stopped).

styla_test(S,R):-
  new_styla_engine(E),
  println(e=E),
  styla_engine_set_goal_string(E,S),
  println(goal_string_set),
  ask_styla_engine(E,R),
  %println(answer=R),
  stop_styla_engine(E),
  println(engine_stopped).
    
 styla_test0:-
    G=member(X,[a,b,c]),
    styla_test(X,G,R),
    println(result0=R).
   
 styla_test:-
    G=functor(X,f,5),
    styla_test(X,G,R),
    println(result=R).
       
 styla_test1:-
    G='member(X,[a,b,c])',
    styla_test(G,R),
    println(result=R).   
    
    
styla_test2:-styla_all(X,member(X,[1,2,3]),Xs),println(Xs),fail.    