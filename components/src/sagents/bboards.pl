% Basic multi-threaded Linda operations 

%% in(X): waits until out(X) makes X available on the Linda blackboard
in(X):-in(X,the(X)).

%% all(G,Xs): collects all matching X on the Linda blackboard
all(G,Xs):-all(G,G,Xs).

%% rd(X): wait until a matching X is on the Linda blackboard
rd(X):-rd(X,the(X)).

%% cin(X): take X if on the Linda blackboard, fail otherwise
cin(X):-cin(X,the(X)).

%% wait_for(Pattern,Constraint): wait for Pattern on the Linda blackboard such the Constraint holds
wait_for(P,C):-wait_for(P,C,P).

%% notify_about(Pattern): notify a thread waiting for Pattern on the Linda balckboard that it is now available
notify_about(P):-notify_about(P,true).

%% out(Data): puts Data on the blackboard and notifies a waiting in(MatchingPattern)
out(X):-
   out(X,R),
   bind_out(R,X).
   
%% to speed up Linda blackboard operations add index declarations for tuples used by in, out !!!

% ---------

bb_assert(X):-db_assert('$bb',X).
bb_retract(X):-db_retract1('$bb',X).
bb_clause(H,B):-db_clause('$bb',H,B).
bb_call(H):-topcall(H).



bind_out(no,_).
bind_out(the(X),X).  
   
out(X,_R):-var(X),!,errmes('out: nonvar expected',culprit(X)). 
out(X,R):-
  cin(waiting(X,_),W),
  do_out(W,X,R).

do_out(no,X,no):-bb_assert(X).
do_out(the(waiting(X0,Hub)),X,the(X0)):-
  copy_term(X0,CX),
  copy_term(X,CX),
  bb_assert(CX),
  thread_resume(Hub).


in(X,R):-do_in(0,X,R).

do_in(Timeout,X,R):-
  cin(X,O),
  do_in(O,Timeout,X,R).

do_in(the(X0),_,_,the(X0)).
do_in(no,Timeout,X,R):-
   hub_ms(Timeout,H),
   bb_assert(waiting(X,H)),
   thread_suspend(H),
   cin(X,R),
   ( R=the(_) -> hub_stop(H)
   ; true
   ).

all(X,G,Xs):-findall(X,bb_clause(G,true),Xs).

% bboard constraint triggers

wait_for(X,_C,_R):-var(X),!,errmes('wait_for: nonvar expected',culprit(X)).   
wait_for(P,C,R):-
  if(take_pattern(available_for(P),C,available_for(R0)),
    =(R,R0),
    make_waiting(P,C,R)
  ).

make_waiting(P,C,R):-
  out(waiting_for(P,C)),
  in(holds_for(P,C),the(holds_for(R,_))).

take_pattern(X,C):-take_pattern(X,C,X).

take_pattern(X,C,R):-
  % println(entering(take_pattern(X,C))),
  all(X,Ps),
  member(X,Ps),
  % println(before(C)),
  bb_call(C),
  % println(after(C)),
  cin(X,the(R)).

% bboard constraint notifiers


notify_about(P,B):-do_notify_about(P,B,yes).

do_notify_about(X,_B,_R):-var(X),!,errmes('notify_about: nonvar expected',culprit(X)).   
do_notify_about(P,B,R):-
  bb_call(B),
  notify_about0(P,R).

notify_about0(P,R):-notify_about0(P),!,R=yes.
notify_about0(_,no).

notify_about0(P):-
  take_pattern(waiting_for(P,C),C,_),
  out(holds_for(P,C)).
notify_about0(P):-
  out(available_for(P)).

all_for(P,Ps):-
  =(A,available_for(P)),
  all(A,As),
  findall(P,member(A,As),Ps).

/*
show_suspended:-
  listing(waiting/2),
  listing(waiting_for/2),
  listing(available_for/1),
  listing(holds_for/2).
*/

% additional db operations



cin(X,_R):-var(X),!,errmes('cin: nonvar expected',culprit(X)).
cin(X,R):-copy_term(X,CX),bb_retract(CX),!,R=the(CX).
cin(_,no).


rd(X,R):-cin(X,R),do_rd(R).

do_rd(no).
do_rd(the(X)):-bb_assert(X).

cout(X):-cout(X,_).

cout(X,_R):-var(X),!,errmes('cout: nonvar expected',culprit(X)).
cout(X,R):-cin(X,W),do_cout(W,X,R).

do_cout(no,X,no):-bb_assert(X).
do_cout(the(X0),_,the(X0)).

set_prop(F,X):-functor(T,F,1),cin(T,_),arg(1,T,X),bb_assert(T).

get_prop(F,X):-functor(T,F,1),all(T,Xs),get_prop_from(Xs,X).

get_prop_from([],no).
get_prop_from([FX],the(X)):-arg(1,FX,X).


hub_ms(_,Hub):-hub(Hub).

bigdata(N,Xs):-numlist(0,N,Xs).

bigassert:-bigassert(50000).

bigassert(Size):-
  bigdata(Size,D),
  abolish(big/1),
  assert((big(X):-if(X=[],true,X=D))).

bigbb:-bigbb(50000).
  
bigbb(Size):-
  bg(bigclient1(Size)),
  bg(bigclient2(Size)).
  


bigclient1(N):- 
  bigdata(N,Xs),
  for(I,1,10),
    in(a(X,_)),println(linda_in(a(X))),
    out(b(I,Xs)),println(linda_out(b(I))),
  fail
  ;
  true.
  
bigclient2(N):-
  bigdata(N,Xs),
  for(I,1,10),
    out(a(I,Xs)),println(linda_out(a(I))),
    in(b(X,_)), println(linda_in(b(X))),  
  fail
  ;
  true.
  
