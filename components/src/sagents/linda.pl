% linda.pl: Basic interprocess Linda operations 

%% run_linda_server(Port): starts Linda server on Port
run_linda_server(Port):-run_server(Port).

%% in(H,P,X): waits until out(X) makes X available on the Linda blackboard at H:P
in(H,P,X):-ask_linda(H,P,in(X)).

%% all(H,P,G,Xs): collects all matching X on the Linda blackboard at H:P
all(H,P,G,Xs):-ask_linda(H,P,all(G,Xs)).

%% rd(H,P,X): wait until a matching X is on the Linda blackboard at H:P
rd(H,P,X):-ask_linda(H,P,rd(X)).

%% cin(H,P,X): take X if on the Linda blackboard at H:P, fail otherwise
cin(H,P,X):-sleep_ms(50),ask_linda(H,P,cin(X)).

%% wait_for(H,P,Pattern,Constraint): wait for Pattern on the Linda blackboard at H:P such the Constraint holds
wait_for(Host,Port,P,C):-ask_linda(Host,Port,wait_for(P,C)).

%% notify_about(H,P,Pattern): notify a thread waiting for Pattern on the Linda blackboard at H:P that it is now available
notify_about(H,P,Pattern):-ask_linda(H,P,notify_about(Pattern)).

%% ask_linda(H,P,G): asks Linda server on port to run Linda operation G
ask_linda(H,P,G):-remote_run(H,P,G).

%% out(H,P,X): puts X to Linda blackboard at H:P and triggers a matching in/3
out(H,P,X):-ask_linda(H,P,out(X)).

%% to speed up Linda blackboard operations add index declarations for tuples used by in, out !!!


nbb:-
  bg(nclient1),
  bg(nclient2).
  


nclient1:-
 wait_for(a(X),X>5),
 println(got(X)).
 
  
nclient2:-
  for(I,1,10),
    notify_about(a(I)),println(notify_about(a(I))),
  fail
  ;
  true.
  
  