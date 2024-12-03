% tests

launch_spaces:-launch_spaces(3).

launch_spaces(MaxCPU):-
  rli_start_broker,
  dynamic(launched/1),
  findall(G,
    (
      for(I,1,MaxCPU),
      G=(done(I):-launch_space(MaxCPU,I))
    ),
    Gs
    ),
  multi_all(Gs,Done),
  println(Done).
  
launch_space(MaxCPU,N):-
  traceln(launching(on_cpu(N/MaxCPU))),
  JavaArgs=[
   '-Xmx512M'
  ],
  JavaPathAtom='',
  LPrologJarFile='../../lprolog.jar',
    atom_concat(space_,N,SP),atom_codes(SP,Space),
    atom_concat(landlord_,N,LL),atom_codes(LL,LandLord),
  Args0=[
    call_with_codes(qcompile,"lagent_tests.pl"),
    % call_with_codes(load,"mypxfile"),
    call_with_codes(start_space,Space),
    call_with_codes(l_agent,LandLord)
  ],
  current_dir(Dir),
  spawn_lprolog(0,JavaArgs,JavaPathAtom,LPrologJarFile,Dir,Args0, Process,_Output),
  println(launched(Process)),
  assert(launched(Process)).
  
kill_spaces:-
  foreach(launched(Process),kill_my_process(Process)),
  retractall(launched(_)).
  
  
  

local_agent_test:-
  assert(friends(cool_people)),
  alice@[bob,cindy], % alice follows bob and cindy
  alice@assert(like(macs)),
  alice@assert(like(popcorn)),
  alice@assert(hate(candy)),
  alice@((hate(pcs):-true)), % shorthand for assert
  cindy@[alice,bob], % cindy starts following alice
  bob@((like(X):-alice@hate(X))),  % bob likes what alice hates
  foreach(cindy@friends(X),println(friends:X)),
  foreach(bob@like(X),println(bob:likes(X))),
  foreach(alice@like(X),println(alice:likes(X))),
  foreach(cindy@hate(X),println(cindy:hates(X))).
  
 
 agtest1:-
  %alice@[bob,cindy], % alice follows bob and cindy
  alice@[bob], % alice follows bob
 
  bob@assert(apple(yellow)),
  bob@assert(apple(red)),
  cindy@assert(apple(green)),
  cindy@assert(apple(red)),
  foreach(
    alice@apple(X),
    println(X)
  ),
  alice@[cindy], % alice follows bob
  foreach(
    alice@apple(X),
    println(X)
  ).

% TESTS


  
% cooperative coop_in/coop_out/coop_all based coordination with engines

test_coordinator1:-
  new_coordinator(C),
  
  new_task(C,
    foreach(
      member(I,[0,2,4,6,8]),
      ( coop_in(a(I,X)),
        println(coop_in=X)
      )
    )
  ),
  
  Xs=[5,7,0,3,9,2,4,6,1,8],
  new_task(C,
    foreach(
      member(I,Xs),
      ( 
        println(coop_out=f(I)),
        coop_out(a(I,f(I)))
        
      )
    )
  ),
  
  new_task(C,
    foreach(
      member(I,[1,3,5,7]),
      ( coop_in(a(I,X)),
        println(coop_in=X)
      )
    )
  ),
  
  new_task(C,
      ( 
        coop_in(a(9,A)),
        println(coop_in_9=A),
        coop_all(a(_,_),Ts),
        println(coop_all=Ts)
      )
  ),
  
  coordinate(C),
  db_listing(C),
  stop_coordinator(C).

test_coordinator:-
  new_coordinator(C),
  
  new_task(C,
    foreach(
      member(I,[0,2]),
      ( coop_in(a(I,X)),
        println(coop_in=X)
      )
    )
  ),
  
  Xs=[3,2,0,1],
  new_task(C,
    foreach(
      member(I,Xs),
      ( 
        println(coop_out=f(I)),
        coop_out(a(I,f(I)))
        
      )
    )
  ),
  
  new_task(C,
    foreach(
      member(I,[1,3]),
      ( coop_in(a(I,X)),
        println(coop_in=X)
      )
    )
  ),
  
  
  coordinate(C),
  stop_coordinator(C).


big_coop_test:-
  time(big_coop_test(10000)).
  
big_coop_test(M):-
  C='$big',
  N is M-1,
  NMax is 2*N+1,
  new_coordinator(C),
  
  new_task(C,
   in_test_task(N,0)
  ),
  
  new_task(C,
   out_test_task(NMax)
  ),
  
  new_task(C,
   in_test_task(N,1)
  ),
  
  coordinate(C),
  
  listings,
  
  stop_coordinator(C).


in_test_task(N,OneOrZero):-
  for(I,0,N),
    OddorEven is 2*I+OneOrZero,
    coop_in(a(OddorEven,_X)).

out_test_task(N):-
  for(I,0,N),
    coop_out(a(I,f(I))).      
 

 /*
main ?- test_coordinator.
coop_out = f(3)
coop_out = f(2)
coop_out = f(0)
coop_in = f(0)
coop_out = f(1)
coop_in = f(2)
coop_in = f(1)
coop_in = f(3)
true.
*/
  
  % end
  
coop_mes_test:-
  coop_mes_test(3).
    
coop_mes_test(N):-
  C='$mes_coord',
  alice@[],bob@[],cindy@[],
  new_coordinator(C),
  N2 is N*2,
  new_task(C, (
     for(_,1,N2),
       alice@handle_msg(From,m(I)),
       println(alice_got(From,m(I)))
    )
  ),
  new_task(C, (
    for(I,1,N),
      println(bob_sent(alice,m(I))),
      bob@send_msg(alice,m(I))
    )
  ),
  new_task(C,(
    for(I,1,N),
      println(cindy_sent(alice,m(I))),
      cindy@send_msg(alice,m(I))
    )
  ),
  coordinate(C),
  db_listing(C),
  stop_coordinator(C).

fgo:-french_space.
ego:-english_space.

french_space:-
  start_space(french_space),
  assert(when_arriving_say(bonjour)),
  assert(when_leaving_say(aurevoir)),
  rli_wait(english_space),
  wait_for_agent(bob),
  alice@[bob],
  alice@salutations,
  alice@visit(english_space).

english_space:-
  start_space(english_space),
  assert(when_arriving_say(hello)),
  assert(when_leaving_say(goodbye)),
  bob@[],
  bob@((salutations:-
        when_arriving_say(A),
        println(A),
        when_leaving_say(B),
        println(B))),
  bob@visit(french_space),
  wait_for_agent(alice),
  bob@unvisit(french_space),
  alice@[bob],
  alice@salutations.

        
  
  

  
 
  
   
