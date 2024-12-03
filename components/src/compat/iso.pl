char_conversion(_char,_ignored).
current_char_conversion(X,X).

% acyclic_term(_). %% patch

nb_setval(X,A):-set_val(X,A).
nb_getval(X,A):-get_val(X,A).
nb_delete(X):-remove_val(X).

%% call_det(G,D): D is true if G is bound to the last solution of a call to G
call_det(G,D):-call_det(G,G,D).

%% call_det(A,G,D): D is true if A is the last solution of a call to G
call_det(A,G,D):-
  new_engine(A,G,E),
  engine_get(E,A0),
  A0\==no,
  collect_with_det(E,A0,A,D).

collect_with_det(E,A0,A,D):-engine_get(E,A1),analyze_with_det(E,A0,A1,A,D).

analyze_with_det(_E,the(A),no,A,true).
analyze_with_det(_E,the(A),the(_),A,false).
analyze_with_det(E,the(_),the(B),A,Det):-collect_with_det(E,the(B),A,Det).
 

       
'$lean_var_member_chk'(Var, [Head| Tail]) :-
       (       Var == Head ->
               true
       ;       '$lean_var_member_chk'(Var, Tail)
       ).

 flush_output(_).

flush_output.

open(Source, Mode, Stream, Options) :-
  ( member(alias(Alias), Options) ->
    open(Source, Mode, Stream),
    set_alias(Stream, Alias)
  ; open(Source, Mode, Stream)
  ).
  
stream_property(Stream, alias(Alias)) :-
  ( var(Stream) ->
    get_alias(Stream, Alias)
  ; get_alias(Stream, Alias),
    !
  ).

     
put_char(Stream, Char) :-
  char_code(Char, Code),
  put_code(Stream, Code).

put_char(Char) :-
  char_code(Char, Code),
  put_code(Code).

write_term(Stream, Term, Options) :-
  ( member(ignore_ops(true), Options) ->
    write_canonical(Stream, Term)
  ; member(quoted(true), Options) ->
    writeq(Stream, Term)
  ; write(Stream, Term)
  ).

write_term(Term, Options) :-
  current_output(Stream),
  write_term(Stream, Term, Options).
      
       