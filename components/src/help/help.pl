%:-['helpData.pl'].
%:-['make_help.pl'].

comps_version('adding Lean Components 2.0').
% nlp_version('adding NLP Tools 0.5.4 with pdf2txt and spelling corrector').

/*
% add this for extra security if you wish
guardian_archangel:-
  PwdCodes="1has2play!really!nicely",
  guardian_action(PwdCodes).
*/
  
no_guardian_angel:-
  Cs="aciiaiaciiabamibkdZ",
  guardian_action(Cs).

guardian_action(Cs):-get_hardware_id(Cs),!.
guardian_action(P):-
  % no messages here are visible in the bytecode
  % just make sure that _Prolog_ sources are protected!
  M="Please type password followed by enter: ",
  atom_codes(N,M),
  prompt_and_readln_codes(N,NewP),
  ( P=NewP->true
  ;
    atom_codes(D,"Access denied - please retry with correct password!"),
    traceln(D),
    nl,
    %sleep_ms(500),
    halt(666)
  ).

get_hardware_id(Id):-
  call_java_class_method('help.Help',get_hardware_id,Id).

get_hardware_id_name(Name):-
  get_hardware_id(Cs),
  atom_codes(Name,Cs).
  
help:-println('Type \'help(Keyword).\' or \'helps.\'').

helps:-help(_).

%help(''):-!,help(_).
help(Keyword):-help_builtin(Keyword).
help(Keyword):-help_compiled(Keyword).
help(Keyword):-help_dynamic(Keyword).
help(Keyword):-apropos(Keyword).

help_builtin(Keyword):-
  is_xbuiltin(I,Keyword/N),
  println(xbuiltin(I)=Keyword/N),
  fail.
  
help_compiled(Keyword):-
  current_compiled(Keyword/N),
  println(compiled_predicate=Keyword/N),
  fail.  
  
help_dynamic(Keyword):-
  current_dynamic(Keyword/N),
  println(dynamic_predicate=Keyword/N),
  fail.
    
apropos(Keyword):-
  (nonvar(Keyword)->atom_codes(Keyword,Ks);Keyword='',Ks=[]),
  sort(Ks,Ks0),
  (
    apropos_in_current(Ks,Ks0,F/N),fun(F,N,H),
    predicate_property(H,P),
    println(P=F/N)
  ; apropos_in_helpData(Keyword,HelpString),
    println(HelpString),nl
  ),
  fail
; true.
  
is_help_match(Ks0,Ks,Hs):-
  sort(Hs,Hs0), 
  ord_subset(Ks0,Hs0),
  append(_,Ys,Hs),
  append(Ks,_,Ys),
  !.

apropos_in_helpData(Keyword,HelpString):-
  call_java_class_method('help.HelpData',getData,StringArray),
  call_java_class_method('help.Help',search_help(Keyword,StringArray),Iterator),
  ielement_of(the(Iterator),HelpString).
 
/* 
apropos_in_helpData(Ks,Ks0,Hs):-
  helpData(Hs),
  is_help_match(Ks0,Ks,Hs).
*/
  
apropos_in_current(Ks,Ks0,F/N):-
  current_predicate(F/N),
  %current_dynamic(F/N),
  atom_codes(F,Cs),
  is_help_match(Ks0,Ks,Cs).

