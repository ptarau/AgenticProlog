% Linda blackboard API

/*

client in(X) 
  - assume: bg(s_server) running here, port known
  - ask the server to call back on port with hub number n
  - wait un hub number n

server in(X,MyHost,MyPort,MyHubNo)
  - if matching available(X) found, call back with it on MyPort,MyHubNo
    if not, record waiting(X,MyHost,MyPort,MyHubNo) for future outs
    
server out(X):
    if waiting(X,MyHost,MyPort,MyHubNo) callback
    if not, store available(X)

client out(X)
  - ask the server to:
      wake up matching in, if available
    if not store available(X) on server for future in(X)   
*/

%% linda_server: starts linda server on default port
linda_server:-
  default_s_port(P),
  linda_server(P).
  
%% linda_server(Port): start linda server on Port
linda_server(Port):-
  bg(s_server(Port)),
  index(available(1)),
  index(waiting(0,0,0,1)).

stop_linda_server:-
  default_s_port(P),
  stop_linda_server(P).

stop_linda_server(Port):-
  s_call(Port,abolish(available/1)),
  s_call(Port,abolish(waiting/4)),
  s_stop(Port).
  
%% linda_client(CallBackPort): starts Linda client and waits to connect to default server
linda_client(MyP):-default_s_port(ServerP),linda_client(ServerP,MyP).

%% linda_client(ServerP,MyP): starts Linda client and waits to connect to ServerP and be called back at MyP on localhost
linda_client(ServerP,MyP):-linda_client(localhost,ServerP,localhost,MyP).

%% linda_client(ServerH,ServerP,MyH,MyP): starts Linda client and waits to connect to ServerH:ServerP and be called back at MyH:MyP
linda_client(H,P,MyH,MyP):-linda_client(H,P,MyH,MyP,true).

%% linda_client(ServerH,ServerP,MyH,MyP,Goal): starts Linda client with Goal and waits to connect to ServerH:ServerP and be called back at MyH:MyP
linda_client(H,P,MyH,MyP,Goal):-
  s_wait(H,P),
  bg(s_server(MyP,Goal)),
  here(MyH,MyP),
  there(H,P),
  index(in(1,0)),
  s_wait(MyH,MyP).

%% linda_in(X): waits until X is put on Linda server when it is called back at port defined with linda_client/4
linda_in(X):-there(H,P),here(MyH,MyP),client_in(H,P,MyH,MyP,X).

%% out(X): puts X on the Linda server possibly triggering waiting in/1 on another client
linda_out(X):-there(H,P),client_out(H,P,X).

%% all(X,Xs): gets snapshot containing all Xs matching X on Linda server
linda_all(X,Xs):-there(H,P),client_all(H,P,X,Xs).

% client_in(Host,Port,MyHost,MyPort,X): waits until X is put on Linda server when it is called back
client_in(H,P,MyH,MyP,X):-
  gensym_no(hub,No),
  hub(Hub),
  db_assertz('$linda',in(No,Hub)),
  s_call(H,P,ignore,server_in(MyH,MyP,No,X),_),
  ask_interactor(Hub,X),
  stop(Hub).

in_callback(No,X):-
   db_retract1('$linda',in(No,Hub)),
   !,
   bg(tell_interactor(Hub,X)).
  
server_in(H,P,No,X):-
  db_retract1('$linda',available(X)),
  !,
  s_call(H,P,ignore,in_callback(No,X),_).
server_in(H,P,No,X):-
  db_assertz('$linda',waiting(H,P,No,X)).
    
server_out(X):-
  db_retract1('$linda',waiting(H,P,No,X)),
  !,
  s_call(H,P,ignore,in_callback(No,X),_).
server_out(X):-
  db_assertz('$linda',available(X)).

%  client_out(H,P,X): puts X on the Linda server possibly triggering waiting in    
client_out(H,P,X):-
  s_call(H,P,ignore,server_out(X),_).

client_all(H,P,X,Xs):-
  s_call(H,P,Xs,server_all(X,Xs),the(Xs)).

server_all(X,Xs):-findall(X,db_clause('$linda',available(X),true),Xs).
  

%% here(Port): same as here(localhost,Port)
here(P):-here(localhost,P).

%% here(Host,Port): sets a pair Host,Port where a server is running as the callback address of this process
here(H,P):-nonvar(H),nonvar(P),!,here<=(H:P).
here(H,P):-here=>(H:P).

%% there(Port): same as there(localhost,Port)
there(P):-there(localhost,P).

%% there(Host,Port): sets the pair Host,Port as the server target for Linda operations 
there(H,P):-nonvar(H),nonvar(P),!,there<=(H:P).
there(H,P):-there=>(H:P).



    
       
     
  
    