% opens a 1-to-1 transaction oriented dialog between two peers
% the 2 peers reuse a connection over which they can send
% exclusive remote execution requests in arbitrary order
% during the dialog, other peers knocking at the same port will be put on wait
% dialogs are memory robust - no leeks observed under heavy testing in ver. 1.0.8

%% open_dialog(MyPort,YourPort): opens a dedicated high-volume communication channel on localhost
open_dialog(MyPort,YourPort):-open_dialog(localhost,MyPort,YourPort).

open_dialog(SameHost,MyPort,YourPort):-
   open_dialog(SameHost,MyPort,SameHost,YourPort).

%% open_dialog(MyHost,MyPort,YourHost,YourPort): opens a dedicated high-volume communication channel
open_dialog(MyHost,MyPort,YourHost,YourPort):-
  (MyHost,MyPort)\==(YourHost,YourPort),
  s_wait(MyHost,MyPort),
  s_wait(YourHost,YourPort),
  %traceln('END WAITING'),
  add_peer(YourHost,YourPort).

%% close_dialog(MyPort,YourPort): closes communication channel on localhost
close_dialog(MyPort,YourPort):-
  close_dialog(localhost,MyPort,YourPort).

close_dialog(SameHost,MyPort,YourPort):-
  close_dialog(SameHost,MyPort,SameHost,YourPort).

%% close_dialog(MyHost,MyPort,YourHost,YourPort): closes high-volume communication channel 
close_dialog(MyHost,MyPort,YourHost,YourPort):-
  (MyHost,MyPort)\==(YourHost,YourPort),
  remove_peer(YourHost,YourPort).
  
add_peer(Host,Port):-
  db_clause('$peers',peer(Host,Port,_),true),
  !.
add_peer(Host,Port):-
  s_connection(Host,Port,C),
  index(peer(1,1,0)),
  db_assert('$peers',peer(Host,Port,C)).

remove_peer(Host,Port):-
  db_retract1('$peers',peer(Host,Port,C)),
  s_disconnect(C).
  
ask_peer(Port,G):-ask_peer(localhost,Port, G,G, the(G)).
 
ask_peer(X,G,R):-there(H,P),ask_peer(H,P,X,G,R).

%% ask_peer(H,P, X,G, R): after open_dialog/2, asks peer at H:P to compute G and return answer the(X) or no in R
ask_peer(H,P, X,G, R):-
  do_goal('$peers',peer(H,P,C)),
  s_run_at(C,X,G,R).
  
  