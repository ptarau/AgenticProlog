%% file compat.pl: various backward comaptibility extensions

%:-['file_io.pl'].
:-['iso.pl'].
:-['sys.pl'].
:-['assumptions.pl'].
:-['db_hash.pl'].

% regexp tools with  AGs + high order

one(F,[X])--> dcg_call(F,X).

star(F,[X|Xs])--> dcg_call(F,X),!,star(F,Xs).
star(_,[])-->[].

plus(F,[X|Xs])--> dcg_call(F,X),star(F,Xs).

dcg_call(F,X,D,S1,S2):-FX=..[F,X,D,S1,S2],topcall(FX). %,println(called=FX).

dcg_call(F,X,S1,S2):-FX=..[F,X,S1,S2],topcall(FX). %,println(called=FX).

% basic thread coordination API

hub_stop(H):-
  invoke_java_method(H,stop_interactor,_).

thread_suspend(Hub):-
  hub_collect(Hub,_).

thread_resume(Hub):-
  hub_put(Hub,true).

send_term(Hub,Term):-hub_put(Hub,Term).

receive_term(Hub,Term):-hub_collect(Hub,Term).


hub_collect(H,T):-ask_interactor(H,T).
  
hub_put(H,T):-tell_interactor(H,T).

  
appendN(Xss,Xs):-append(Xss,Xs).
  
% deprecated

delete_java_object(_,_).  

file2codes(F,Cs):-file2string(F,S),atom_codes(S,Cs).

file2chars(F,Cs):-file2codes(F,Cs).

% file2codes(F,Cs):-find_file(F,File),findall(C,code_of(File,C),Cs).

jartest:-
  JarName='/Users/tarau/Desktop/sit/code/prologL/lprolog.jar',
  FileNameInJar='lwam.bp',
  NewFileName='newlwam.bp',
  file_from_jar(JarName,FileNameInJar,NewFileName).  
    
%% file_from_jar(JarName,FileNameInJar,NewFileName): extracts a file from a .jar container 
file_from_jar(JarName,FileNameInJar,NewFileName):-
  call_java_class_method('compat.Tools',jar2file(JarName,FileNameInJar,NewFileName),_).

file2string(URL,S):-
  find_file(URL,F),
  call_java_class_method('compat.Tools',file2string(F),S).
 
string2file(S,F):-
  atom_codes(S,Xs),
  codes2file(Xs,F).

codes2file(Xs,F):-
  telling(TF),
  tell(F),
  write_codes(Xs),
  told,
  tell(TF).
  
sread(S,T):-atom_to_term(S,T,_).

swrite(T,S):-term_to_atom(T,S). 

term_codes(T,Cs):-nonvar(T),!,swrite(T,S),atom_codes(S,Cs).
term_codes(T,Cs):-atom_codes(S,Cs),sread(S,T).

% blackboard operations

bb_init:-index('$bb'(1,1,0)).

bb_val(A,B,V):-nonvar(A),nonvar(B),bb_val0(A,B,R),!,R=V.

bb_rm(A,B):-nonvar(A),nonvar(B),db_retract('$bb','$bb'(A,B,_)),!.

bb_def(A,B,V):-nonvar(A),nonvar(B),bb_def1(A,B,V).

bb_def1(A,B,_):-bb_val(A,B,_),!,fail.
bb_def1(A,B,V):-db_assert('$bb','$bb'(A,B,V)).

bb_let(A,B,_):-bb_rm(A,B),fail.
bb_let(A,B,V):-bb_def(A,B,V).

bb_val0(A,B,V):-db_clause('$bb','$bb'(A,B,V),_).

bb_set(A,B,V):-bb_val(A,B,_),bb_let(A,B,V).

bb:-foreach(bb_val(A,B,V),println((A,B)=>V)).

bb_def(A,_):-bb_val(A,_),!,fail.
bb_def(A,V):- A<==V.

bb_let(A,V):-A <== V.
bb_val(A,V):-A ==> V.
bb_set(A,V):- A==>_,A<==V.
bb_rm(A):-gvar_remove(A).

% compat

val(X,Y,Z):-bb_val(X,Y,Z).
def(X,Y,Z):-bb_def(X,Y,Z).
set(X,Y,Z):-bb_set(X,Y,Z).
let(X,Y,Z):-bb_let(X,Y,Z).
rm(X,Y):-bb_rm(X,Y).

val(X,Y):-bb_val(X,Y).
def(X,Y):-bb_def(X,Y).
let(X,Y):-bb_let(X,Y).
set(X,Y):-bb_set(X,Y).
rm(X):-bb_rm(X).

%det_append(Xs,Ys,Zs):-append(Xs,Ys,Rs),!,Zs=Rs.

make_cmd0(Lss,Cs):-make_cmd(Lss,C),atom_codes(C,Cs).
 
make_cmd([],'').
make_cmd([X|Xs],C2):-to_cmd(X,C0),make_cmd(Xs,C1),namecat(C0,C1,'',C2).

to_cmd(X,C):-atom(X),!,C=X.
to_cmd(X,C):-number(X),!,to_string(X,C).
to_cmd([X|Xs],C):-integer(X),!,atom_codes(C,[X|Xs]).
to_cmd(Bad,_):-throw(bad_data(make_cmd,Bad)).


object_to_string(O,S):-invoke_java_method(O,toString,S).


list_array(Xs,A):-
  list_vector(Xs,S),
  invoke_java_method(S,toArray,A),
  delete_java_object(S).

list_vector(Xs,S):-
  new_java_object('vm.logic.ObjectStack',S),
  add_all_members(Xs,S).

add_all_members(Xs,S):-
  member(X,Xs),
  invoke_java_method(S,push(X),_),
  fail.
add_all_members(_,_).

% converts an array to a Prolog list (keys: array2list, array_to_list)

array_list(Array,List):-findall(X,array_element_of(Array,X),List).

array_element_of(Array,X):-
  array_size(Array,L),
  Last is L-1,
  for(I,0,Last),
    array_get(Array,I,X).
    
    
    
% serialize object
object2file(O,File):-
  call_java_class_method(
      'vm.extensions.Transport',
      toFile(File,O),_
  ).
 
% rebuild serialized object  
file2object(File,O):-  
  call_java_class_method(
    'vm.extensions.Transport',
    fromFile(File),O
  ).    
  
  
nth_member(X,Xs,N):-member_i(X,Xs,1,N).

nth_member0(X,Xs,N):-member_i(X,Xs,0,N).
  
map(F,Xs):-maplist(F,Xs).
map(F,Xs,Ys):-maplist(F,Xs,Ys).
map(F,Xs,Ys,Zs):-maplist(F,Xs,Ys,Zs).

%% sentence_of(F,ListOfWords): bactkracks over sentences terminated with .!? in a file returning ListOfWords
sentence_of(F,Ws):- 
  Ends=".!?",sentence_of(F,Ends,Xs),
  codes_words(Xs,Ws).
     
sentence_of(URL,Ends,Xs):-
  find_file(URL,F),
  open(F,read,Reader),
  pick_code_of(Reader,Ends,Xs).

pick_code_of(F,Ends,Ys):-
  getx(F,X),
  collectx(Ends,X,F,Xs,More),
  select_code_from(F,Ends,Xs,Ys,More).

select_code_from(_,_,As,As,_).
select_code_from(I,Ends,_,Xs,yes):-pick_code_of(I,Ends,Xs).

collectx(_,no,_,".",no):-!.
collectx(Ends,the(End),_,[End],yes):-member(End,Ends),!.
collectx(Ends,the(X),F,[X|Xs],More):-
   getx(F,NewX),
   collectx(Ends,NewX,F,Xs,More).
    
getx(F,X):-get_the_code(F,X0),hide_nls(X0,X).

get_the_code(F,C):-get_code(F,X),X=\=(-1),!,C=the(X).
get_the_code(_,no).
    
hide_nls(the(10),the(32)):-!.
hide_nls(the(13),the(32)):-!.
hide_nls(X,X).

db_asserted(Db,H):-
  nonvar(H),
  db_clause(Db,H,B),
  call_with(Db,B).
  
asserted(H):-db_asserted('$',H).

sum(Xs,S):-sumlist(Xs,S).

namecat(A,B,C):-concat_atom([A,B],C).

% they use WAM-level means as change_arg/3 in has_fuel/3
% the reader is challenged to express them in classical Prolog :-)
% To do more, a separate Prolog engine or first order manipulation
% of OR continuations is needed...

%% while(C,G): answers G as far as constraint C holds
while(C,G):-G,(C->true;!,fail).

skip_until(C,G):-G,(C->fail;!).

skip_when(C,G):-G,(C->fail;true).

%% nth_answer(N,G): gives only the N-th answer of G
nth_answer(N,G):-N1 is N-1,Max=s(N1),skip_until(has_fuel(Max),G).

%% take_at_most(N,G): generates at most the first N answers of G
take_at_most(N,G):-Max=s(N),while(has_fuel(Max),G).

%% drop_at_least(N,G): drops at least the first N answers of G
drop_at_least(N,G):-Max=s(N),skip_when(has_fuel(Max),G).

% has_fuel(Max): re-entrant on-place counter
has_fuel(Max):-arg(1,Max,N),N>0,N1 is N-1,change_arg(1,Max,N1).

%% find_while(C,X,G,Xs): answer_stream to list converters
find_while(C,X,G,Xs):-findall(X,while(C,G),Xs).

%% find_at_most(N,X,G,Xs): collects, like, findall, at most K answers X of G to Xs
find_at_most(N,X,G,Xs):-findall(X,take_at_most(N,G),Xs).

all_but_at_least(N,X,G,Xs):-findall(X,drop_at_least(N,G),Xs).

%% det_call(G): signals error if G has more than one answer
det_call(G):-find_at_most(2,G,G,Gs),!,
  ( Gs=[]->fail
  ; Gs=[G]->true
  ; % member(G,Gs),
    errmes('expected to be deterministic',G)
  ).
  
  
gensym_reset_no(Root,SymNo):-Root<=SymNo.

gensym_init(Root):-gensym_reset_no(Root,0).

init_gensym(Root):-gensym_reset_no(Root,0).

to_lower_char(C,LC):- [A,Z,LA]="AZa",C>=A,C=<Z,!, LC is (LA-A)+C.
to_lower_char(C,C).

to_upper_char(LC,C):- [LA,LZ,A]="azA",LC>=LA,LC=<LZ,!, C is (A-LA)+LC.
to_upper_char(LC,LC).

to_upper_chars([],[]).
to_upper_chars([X|Xs],[Y|Ys]):-
  to_upper_char(X,Y),
  to_upper_chars(Xs,Ys).

to_lower_chars([],[]).
to_lower_chars([X|Xs],[Y|Ys]):-
  to_lower_char(X,Y),
  to_lower_chars(Xs,Ys).

db_clean(Db):-db_clear(Db).

db_clean:-db_clear.

write_chars(Cs):-write_codes(Cs).

% external Renoir visulaization - temproary

rencall(Xs,G):-
  nonvar(G),
  !,
  bp_terms,
  remote_run(localhost,8421,Xs,G,_),
  java_terms.
rencall(Xs,G):-
  errmes(bad_args,rencall(Xs,G)).

rencall(G):-rencall([],G).

show_rengraph(Es0):-
  to_linear(Es0,Es),
  rencall(show_rengraph(Es)).

show_rencat(Vs0,Ms0):-
  to_linear(Vs0,Vs),
  to_linear(Ms0,Ms),
  %raceln(show_rencat(Vs,Ms)),
  rencall(show_rencat(Vs,Ms)).
  
  
  
pp_clause(C):-portray_clause(C).
  
  
distinct(X,Y):- X\==Y.
  
  
/* 

NO EASY WAY TO DO THIS  

persist_engine(name,X,G):-
  new_engine(X,current_engine_object(X),E),
  get(E,the(O)),
  load_engine(E,X,G),
  name<==O.

get_persisting_engine(name,E):-
  name=>    
  
*/
