% tests
  
  

guiatest:-
  IMax=20,
  N=50,
  for(I,1,IMax),
  guiatest(I,N),
  fail
; println('AGENTS STARTED'),
  sleep(10),
  stop_all_agents.

  
    
guiatest(I,N):-
  atom_concat(a,I,Name),
  new_agent(Name),
  traceln(before(I,N)),
  ask_agent(Name,bigagoal(I,N,_)),
  traceln(after(I,N)).

bigagoal(I,N,Xss):-
  println(step(I,N)),
  forxss(N,Xss).
 
  
test_linda_server:-
  linda_server(4321).

big_term_test:-
  Port=4321,
  if(remote_ping(Port),true,bg(run_linda_server(Port))),
  remote_wait(Port),
  
  % println('start test_linda_server in other window'),
  bigdata(50000,D),
  remote_run(localhost,Port,X,X=D,_),
  println(done).
  
test_linda_clients:-test_linda_clients(50000).
  
test_linda_clients(Size):-
  H=localhost,
  P=4321,
  if(remote_ping(Port),true,bg(run_linda_server(Port))),
  remote_wait(P),  
  bg(test_linda_client1(H,P,Size)),
  bg(test_linda_client2(H,P,Size)).

test_linda_client1(H,P,N):- 
  bigdata(N,Xs),
  for(I,1,10),
    in(H,P,a(X,_)),println(linda_in(a(X))),
    out(H,P,b(I,Xs)),println(linda_out(b(I))),
  fail
  ;
  true.
  
test_linda_client2(H,P,N):-
  bigdata(N,Xs),
  for(I,1,10),
    out(H,P,a(I,Xs)),println(out(H,P,a(I))),
    in(H,P,b(X,_)), println(in(H,P,b(X))),  
  fail
  ;
  true.
  


bigtest:-
  for(I,1,50),
    traceln('**** starting_test'(I)),
    bigtest(20),
    traceln('**** ending_test'(I)),
  fail
; broker_state.

bigtest(N):-
  for(I,1,N),
    atom_concat(testAgent,I,Name),
    traceln(starting_agent(Name)),
    new_agent(Name),
    ask_agent(Name,println(hi(Name))),
  fail
  ; 
  stop_all_agents.
  
% tests callback linda on 3 threads
lback_test:-
  bg(linda_server),
  bg(lclient1),
  bg(lclient2),
  sleep(20),
  stop_linda_server.
  
  
lserver:-linda_server.

lclient1:-  % this would fail above 5000++ as sockets will run linda_out
  linda_client(1111),
  sleep(1),
  (for(I,1,1000),
    linda_in(a(X)),println(linda_in(a(X))),
    linda_out(b(I)),println(linda_out(b(I))),
  fail
  ;
  true
  ),
  s_stop(1111).
  
lclient2:- % this would fail above 5000++ as sockets will run linda_out
  linda_client(2222),
  sleep(1),
  (for(I,1,1000),
    linda_out(a(I)),println(linda_out(a(I))),
    linda_in(b(X)), println(linda_in(b(X))),  
  fail
  ;
  true
  ),
  s_stop(2222).
  
atest1:-
    new_s_agent(alice),
    new_s_agent(bob),
    open_agent(alice,A),
    open_agent(bob,B),
    foreach(
      between(1,2,I),
      (
       tell_agent_at(A,println(hello(alice,I)))
       ,
       tell_agent_at(B,println(hello(bob,I))
       )
      )
    ),
    close_agent(A),
    close_agent(B),
    stop_agent(alice),
    stop_agent(bob),
    stop_broker.

agent_println(X):-println(X).

atest:-
    Max=1000,
    Agents=[alice,bob,cindy,dylan,eli],
    maplist(new_s_agent,Agents),
    maplist(awork_goal(Max),Agents,Goals),
    foreach(member(G,Goals),agent_println(G)),
    foreach(
      mbg(Goals,R),
      agent_println(result_from(R))
    ),
    %sleep_ms(1000),
    maplist(stop_agent,Agents),
    %stop_broker,
    stats.
      
 awork_goal(Max,Agent,(Agent:-awork(Max,Agent))).
   
 awork(Max,Agent):-
   agent_println(starting_work(Agent)),
   open_agent(Agent,Connection),
   foreach(
     between(1,Max, I),
     (
       %agent_println(asking(Agent,I)),
       tell_agent_at(Connection,agent_println(working(Agent,I)))
     )
   ),
   close_agent(Connection),
   agent_println(ending_work(Agent)).
   
 multiagent_test:-
    Max=10,
    Agents=[alice,bob,cindy,dylan,eli],
    maplist(new_s_agent,Agents),
    maplist(mwork_goal(Max),Agents,Goals),
    println(Goals),
    foreach(
      mbg(Goals,R),
      println(result_from(R))
    ),
    %sleep_ms(1000),
    maplist(stop_agent,Agents),
    stop_broker.
      
 mwork_goal(Max,Agent,(Agent:-mwork(Max,Agent))).
   
 mwork(Max,Agent):-
   println(starting_work(Agent)),
   foreach(
     between(1,Max, I),
     (
       ask_agent(Agent,println(working(Agent,I)))
     )
   ),
   println(ending_work(Agent)).
   
       
 bbtest:-
   G1=(linda_in(a(X)),println(X),fail),
   G2=(linda_out(a(222)),println(linda_out(222)),fail),
   maplist(bg,[G1,G1,G1]),
   maplist(bg,[G2,G2,G2]),
   println(launched),
   sleep(2),
   println(done).
   
rbbtest:-
   bg(s_server),
   G1=(s_call(linda_in(a(X))),traceln(X),fail),
   G2=(s_call(linda_out(a(222))),traceln(linda_out(222)),fail),
   maplist(bg,[G1,G1,G1]),
   maplist(bg,[G2,G2,G2]),
   println(launched),
   sleep(2),
   println(done).
   
   
hs(Max,Me,You):-
  bg(s_server(Me)),
  open_dialog(Me,You),
  foreach(
    between(1,Max,I),
    ask_peer(You,
       println(from(Me,You,hello(I)))
    )
  ),
  /*
  (s_ping(Me),s_ping(You)->close_dialog(Me,You);true),
  (s_ping(Me)->s_stop(Me);true),
  (s_ping(You)->s_stop(You);true).
  */
  close_dialog(Me,You),
  s_stop(Me).
     
hstest:-
  bg(hs12),
  hs21.

hstest1:-
  bg(hsA),
  bg(hsB),
  hsC.  
       
hs12:-time(hs(10000,1111,2222)).
hs21:-time(hs(10000,2222,1111)).

hsA:-traceln('needs hsB, hsC'),hs(10000,1111,2222).
hsB:-hs(10000,2222,3333).
hsC:-hs(10000,3333,1111).  
    
