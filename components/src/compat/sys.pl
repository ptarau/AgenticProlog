% os interface
 
system(CmdList,Output):-
  current_dir(Dir),
  system(Dir,CmdList, Output),
  println(Output).

system(Dir,CmdList, Output):-system(Dir,CmdList, Output,_Ret).
    
%% system(Dir,CmdList, Output,RetCode): launches command in Dir waits until it finishes and returns its Output
system(Dir,CmdList, Output,RetCode):-
  Wait=2,
  system(Dir,CmdList,Wait, _, Output,RetCode).

system(Dir,CmdList0,Wait, Process,Output):-system(Dir,CmdList0,Wait, Process,Output,_Ret).

%% system(Dir,CmdList,Wait, Process,Output,RetCode): launches new OS Process in Dir and returns the Process id to be used by kill_my_process/1
system(Dir,CmdList0,Wait, Process,Output,Ret):-
  listify(CmdList0,CmdList),
  new_process(Dir,CmdList,Process),
  run_my_process(Process,Wait,Output,Ret).
  
new_process(DirName,CmdList,Process):-
  length(CmdList,L),
  %traceln([CmdList,L]),
  new_array('java.lang.String',L,CMDs),
  foreach(nth0(I,CmdList,X),array_set(CMDs,I,X)),
  new_java_object('java.lang.ProcessBuilder'(CMDs),PB),
  new_java_object('java.io.File'(DirName),Dir),
  invoke_java_method(PB,directory(Dir),_),
  to_boolean(true,True),
  invoke_java_method(PB,redirectErrorStream(True),_),
  invoke_java_method(PB,start,Process).
  
run_my_process(Process,Wait,Output,Ret):-  
  call_java_class_method('compat.Tools',runProcess(Process,Wait),x(Output,Ret)).

%% kill_my_process(Process): kills process started with system/5
kill_my_process(Process):-
 call_java_class_method('compat.Tools',killProcess(Process),_Output).

listify(X,_):-var(X),!,errmes(unexpected_var,in_listify).
listify([],Ys):-!,Ys=[].
listify([X|Xs],Ys):-!,Ys=[X|Xs].
listify(X,[X]).
  
/*
run_command(Cmd,StringResult):-
  call_java_class_method('compat.Tools',runCommand(Cmd),StringResult).
*/

toString(X,S):-invoke_java_method(X,toString,S).


lprolog(Args):-current_dir(D),lprolog(D,Args).

lprolog(Dir,Args0):-
  lprolog(Dir,Args0,[halt],Output),
  println(Output).
 
%% lprolog(Dir,Args0,Output): launches an lprolog process in Dir, with Args - it is assumed the user will halt it remotely
lprolog(Dir,Args0,Output):-lprolog(Dir,Args0,[],Output).

lprolog(Dir,Args0,FinalCmd0,Output):-lprolog(Dir,Args0,FinalCmd0, _Process,Output).

lprolog(Dir,Args0,FinalCmd0, Process,Output):-
  Wait=2,
  lprolog(Wait,Dir,Args0,FinalCmd0, Process,Output).

%% lprolog(Wait,Dir,Args,FinalCmd, Process,Output): runs new lean Prolog process in Dir and returns the Process id and its Output if Wait>0
lprolog(Wait,Dir,Args0,FinalCmd0, Process,Output):-
  listify(Args0,Args),
  listify(FinalCmd0,FinalCmd),
  maplist(term_to_atom,Args,As),
  maplist(term_to_atom,FinalCmd,Cs),
  append([[lprolog],As,Cs],Cmds),
  %println(lprolog_got(Cmds)),
  system(Dir,Cmds,Wait, Process, Output).

spawn_lprolog(Dir,Args0):-
  spawn_lprolog(Dir,Args0,_Process,Output),
  println(Output).

spawn_lprolog(Dir,Args0,Process,Output):-
  spawn_lprolog('$HOME/go/code/components/lprolog.jar',Dir,Args0, Process,Output).
 
spawn_lprolog(LPrologJarFile,Dir,Args0, Process,Output):-
  JavaArgs=['-Xmx1G'],
  JavaPath=[],
  spawn_lprolog(JavaArgs,JavaPath,LPrologJarFile,Dir,Args0, Process,Output).

spawn_lprolog(JavaArgs,JavaPathAtom,LPrologJarFile,Dir,Args0, Process,Output):-
  Wait=2,
  spawn_lprolog(Wait,JavaArgs,JavaPathAtom,LPrologJarFile,Dir,Args0, Process,Output).
    
spawn_lprolog(Wait,JavaArgs,JavaPathAtom,LPrologJarFile,Dir,Args0, Process,Output):-
  listify(Args0,Args),
  maplist(term_to_atom,Args,As),
  concat_atom([LPrologJarFile,':',JavaPathAtom],JavaPath),
  append([[java],JavaArgs,['-cp',JavaPath],['vm.logic.Start',LPrologJarFile],
          As
         ],
  Cmds),
  (get_verbosity(Vb),Vb>3->println(lprolog_sending_to_system(Cmds));true),
  system(Dir,Cmds,Wait, Process, Output).        

  
  
xfor:-foreach_in_dir_lprolog(println).

pxfor:-par_lprolog(8,println).

par_lprolog(NbOfCPUs,Predicate):-
  current_dir(D),
  par_lprolog(NbOfCPUs,'/Users/tarau/Desktop/go/code/components/lprolog.jar',[],D,Predicate).

par_lprolog(NbOfCPUs,LPrologJarFile,InitArgs,Dir,Predicate):-
  files(Dir,Fs),
  a_group_of(NbOfCPUs,Fs,FewFs),
  findall(O,foreach_file_lprolog(LPrologJarFile,InitArgs,Dir,FewFs,Predicate,O),Os),
  foreach(member(O,Os),println(O)),
  fail
; true.


a_group_of(NbOfCPUs,Fs,FewFs):-
  split_to_groups(NbOfCPUs,Fs,Fss),
  member(FewFs,Fss).

foreach_in_dir_lprolog(Pred):-
  current_dir(D),
  foreach_in_dir_lprolog('/Users/tarau/Desktop/go/code/components/lprolog.jar',[],D,Pred).
 
foreach_in_dir_lprolog(LPrologJarFile,InitArgs,Dir,Predicate):-
 files(Dir,Fs),
 foreach_file_lprolog(LPrologJarFile,InitArgs,Dir,Fs,Predicate).

foreach_file_lprolog(LPrologJarFile,InitArgs,Dir,Fs,Predicate):- 
  println('--------------------'),
  println(InitArgs),
  println('--------------------'),
  foreach_file_lprolog(LPrologJarFile,InitArgs,Dir,Fs,Predicate, Output),
  println(Output),nl,
  fail
; println('======================').
    
foreach_file_lprolog(LPrologJarFile,InitArgs,Dir,Fs,Predicate, Output):- 
  member(File,Fs),
  lprolog_with_file(LPrologJarFile,InitArgs,Dir,File,Predicate, the(Output)).
  
lprolog_with_file(LPrologJarFile,InitArgs,Dir,File,Predicate, the(Output)):- 
  [Dot]=".",
  atom_codes(File,Cs),
  Cs\=[Dot|_],
  append([set_quickfail(4,_)|InitArgs],[call_with_codes(Predicate,Cs),halt(0)],Args1),
  %traceln(Args1),
  spawn_lprolog(LPrologJarFile,Dir,Args1, _Process,Output),
  !.
lprolog_with_file(_LPrologJarFile,_InitArgs,_Dir,_File,_Predicate, no).

call_with_codes(F,Cs):-atom_codes(X,Cs),call(F,X). 

call_with_codes(F,Cs,Ds):-atom_codes(X,Cs),atom_codes(Y,Ds),call(F,X,Y). 

%% file_iterator(AbsolutFileName): returns all absolute file names reachable from current dir  
file_iterator(AbsolutFileName):-
  file_iterator(_Ps,_F,AbsolutFileName).
    
file_iterator(Path,F,AF):-
  current_dir(D),
  file_iterator(D,Path,F,AF).
  
%% file_iterator(TopDir,Path,F,AbsolutFileName): returns files reachable fro current dir
file_iterator(TopDir,Path,F,AF):-
  filter_file_name(TopDir,Dir),
  dir_or_file(Type,Dir,DF),
  ( Type=1,DF=F,Path=[],concat_atom([Dir,'/',DF],AF)
  ; Type=0,
    concat_atom([Dir,'/',DF],NewDir),
    file_iterator(NewDir,Path0,F,AF),
    Path=[DF|Path0]
  ).
  
filter_file_name(F0,F):-
  [Dot]=".",
  (F0='.';atom_codes(F0,[C0|_]),C0=\=Dot),
  !,
  absolute_file_name(F0,F).