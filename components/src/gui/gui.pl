/* 
  Reflection based GUI  
  - the default AWT GUI can be overriden by an external Swing based
    alternative Java implementation
  - looking the same from Prolog, although the external GUI is expected to
    offer extra functionality with time
*/

/* builtin to Java connection tools - based on Reflection based interface */

get_gui_class(CName):-gvar_get(gui,swing),!,CName='jgui.Start'.
get_gui_class('gui.GuiBuiltins').

call_gui_method(MethodAndArgs):-call_gui_method(MethodAndArgs,_).

call_gui_method(MethodAndArgs,Result):-
   get_gui_class(CName),
   call_java_class_method(
      CName,
      MethodAndArgs,
      Result
   ).

		 
/* builtins */

show(Container):-call_gui_method(show(Container)).
  
resize(Component,H,V):-call_gui_method(resize(Component,H,V)).

move(Component,H,V):-call_gui_method(move(Component,H,V)).

get_applet(A):-call_gui_method('get_applet',A).
get_applet_host(H):-call_gui_method('get_applet_host',H).

/* creates a new frame - top window */

new_frame(Frame):-new_frame('',Frame).

% new_frame(Title,Frame):-gvar_get('desktop','virtual'),!,new_inner_frame(Title,Frame).
new_frame(Title,Frame):-new_frame(Title,grid(1,1),Frame).

new_frame(Title,Layout,Frame):-
  Kind=0,
  new_frame(Title,Layout,Kind,Frame). 
  
new_frame(Title,Layout,Kind,Frame):-
  to_layout(Layout,L,X,Y),
  call_gui_method('new_frame'(Title,L,X,Y,Kind),Frame).

new_panel(Parent,Layout,Panel):-
  to_layout(Layout,L,X,Y),
  call_gui_method('new_panel'(Parent,L,X,Y),Panel).

new_label(Parent,Name,Label):-
   call_gui_method('new_label'(Parent,Name),Label).

new_button(Parent,Name,Action,Button):-
   new_engine_object(yes,button_action(Action),Machine),
   Goal='new_button'(Parent,Name,Machine),
   % button will die if action fails!
   call_gui_method(Goal,Button).

new_gui_io(Input,Output,Hub, GuiIO):-
  call_gui_method('new_gui_io'( '?-', Input,Output,Hub), GuiIO).

new_gui_printer(Name,gui_o(O,in(F))):-
  new_frame(Name,F),
  new_panel(F,border,P),
  new_text(P,T),
  new_gui_o(T,O),
  set_output(O),
  show(F).

stop_gui_printer(Handle):-
  Handle=gui_o(_O,in(F)),
  stdio(IO),
  set_output(IO),
  %destroy(O),
  destroy(F).
 

gptest:-
  Name=myprinter,
  open_gui_printer(Name),
  to_gui_printer(Name,one),
  to_gui_printer(Name,two),
  sleep(10),
  close_gui_printer(Name).
  
%% open_gui_printer(Name): opens an output enabled GUI window 
open_gui_printer(Name):-
  new_gui_printer(Name,Handle),
  gvar_set(Name,Handle).

%% use_gui_printer(Name): redirectes output to a GUI window 
use_gui_printer(Name):-
  gvar_get(Name,Handle),
  Handle=gui_o(O,in(_F)),
  set_output(O).

%% to_gui_printer(Name,term): prints to a gui window if it exists
to_gui_printer(Name,Term):-
  gvar_get(Name,Handle),
  !,
  Handle=gui_o(O,in(_F)),
  current_output(Stream),
  println(O,Term),
  set_output(Stream).
to_gui_printer(_Name,Term):-
  println(Term).

%% close_gui_printer(Name): close an output enabled GUI window   
close_gui_printer(Name):-
  gvar_get(Name,Handle),
  stop_gui_printer(Handle),
  gvar_remove(Name). 

s_agent(Name,Port,InitGoal):-
  s_server(Port,0,'$null',(open_gui_printer(Name),InitGoal)).
    
new_gui_o(Output,GuiIO):-
  call_gui_method('new_gui_o'(Output), GuiIO).

  
button_action(Action):-
  repeat,
  (topcall(Action)->true
  ; !,fail
  ).
  
set_label(Label,String):-
   invoke_java_method(Label,setText(String),_).

new_file_dialog(Mode,Result):-
  current_dir(Dir), % if Dir='?', the last one is used - OS dependent
  new_file_dialog(Mode,Dir,Result).

new_file_dialog(Mode,Dir,Result):-
   call_gui_method('new_file_dialog'(Mode,Dir),Result).
   %traceln('FILE:'(Result)).
   
new_text(Parent,Component):-
   new_text(Parent,'',5,20,Component).

new_text(Parent,String,Component):-
   new_text(Parent,String,2,24,Component).
   
new_text(Parent,String,Rows,Cols,Component):-
   call_gui_method('new_text'(Parent,String,Rows,Cols),Component).
   
set_text(Component,String):-
   invoke_java_method(Component,setText(String),_).  

add_text(Component,String):-
   invoke_java_method(Component,append_text(String),_).  

get_text(Component,String):-
   invoke_java_method(Component,getText,String).  


/* Colors */

new_color(R,G,B,Color):-
   call_gui_method('new_color'(R,G,B),Color).

make_white(Color):-new_color(1,1,1,Color).
make_blue(Color):-new_color(0,0,1,Color).
make_light_blue(Color):-B is 10/10,Q is 8/10,new_color(Q,Q,B,Color).
make_gray(Color):-Q is 4/5,new_color(Q,Q,Q,Color).
make_green(Color):-new_color(0,1,0,Color).
make_red(Color):-new_color(1,0,0,Color).
make_black(Color):-new_color(0,0,0,Color).
   
set_fg(Component,Color):-      
  invoke_java_method(Component,setForeground(Color),_).  

set_bg(Component,Color):-      
  invoke_java_method(Component,setBackground(Color),_).  

set_color(Component,Color):-      
  invoke_java_method(Component,setColor(Color),_).  

/* Default Colors */

set_fg_color(R,G,B):-call_gui_method(set_fg_color(R,G,B)).
set_bg_color(R,G,B):-call_gui_method(set_bg_color(R,G,B)).

%get_fg_color(C):-call_gui_method(get_fg_color,C).
%get_bg_color(C):-call_gui_method(get_bg_color,C).

%to_default_fg(Component):-call_gui_method(to_default_fg(Component)).
%to_default_bg(Component):-call_gui_method(to_default_bg(Component)).

    
/* Default Fonts */

set_font_name(Name):-call_gui_method(set_font_name(Name)).
set_font_style(Style):-call_gui_method(set_font_style(Style)).
set_font_size(Size):-call_gui_method(set_font_size(Size)).
inc_font_size(Size):-call_gui_method(inc_font_size(Size)).

to_default_font(Component):-call_gui_method(to_default_font(Component)).

remove_all(Container):-
   invoke_java_method(Container,'removeAll',_).
   
destroy(Component):-
   call_gui_method('destroy'(Component)).

set_layout(Container,Layout):-
   to_layout(Layout,L,X,Y),
   call_gui_method('set_layout'(Container,L,X,Y)).

/* used on Panels and Frames with border layout */

set_direction(Container,String):-
   call_gui_method('set_direction'(Container,String),_).
   
to_layout(grid(X,Y),grid,X,Y):-!.
to_layout(L,L,0,0).





/* EXAMPLES OF GUI APPLICATIONS */


/* simple Prolog Console - reads, evaluates, prints answers */
     
s_console:-default_s_port(P),s_console('Prolog Console',P).

s_console(Port):-s_console('',Port).
     
s_console(Name,Port):-
  traceln(starting(s_console,'type exit to quit')),
  %atom_concat('INPUT DISABLED. PORT=',Port,Mes),
  Mes='println(hello).',
  new_console(Name,Mes,10,20, Frame,Console),
  bg(s_server(Port,init_s_console(Console))),
  %run_console(s_call(Port),Frame,Console).
  %traceln(running(s_console)),
  run_console(s_call(Port),Frame,Console).

run_console(Parent,Console):-run_console(call,Parent,Console).

run_console(Closure,Parent,console(Input,Output,Hub)):- 
  invoke_java_method(Input,requestFocus,_),
  to_gui_io(Input,Output,Hub,_), 
  repeat,
    hub_collect(Hub,Line),
    % traceln(got(Line)),
    ( Line == 'exit' -> true
    ; Line == 'exit.' -> true
    ; do_input_action(Closure,Line,Input,Output),
      fail
    ),
    !,
    to_stdio,
    println(closing_console),
    destroy(Parent),
    stop(Hub).
     
init_s_console(Console):-
  to_gui_io(Console).

stop_s_console:-
   %traceln(got_stop_s_console),
   hub=>Hub,
   !,
   remove_val(hub),
   tell_interactor(Hub,exit).
stop_s_console.

%% stop_s_console(P): stops s_console on this host at P
stop_s_console(P):-stop_s_console(localhost,P).

%% stop_s_console(H,P): stops s_console at H,P
stop_s_console(H,P):-
  s_call(H,P,ok,stop_s_console,the(ok)),
  s_stop(H,P).
  
%% console: starts a console - type exit to quit           
console:-
  console('println(hello).',10,20).

console(Query,L,C):-
  new_console(Query,L,C, Frame,Console),
  run_console(Frame,Console).
 
finalize_frame:-
   traceln('Finalizing Frame'),
   halt. 
  

new_console(Query,L,C, F,Console):-new_console('',Query,L,C, F,Console).

new_console(Title,Query,L,C, F,Console):-
  new_frame(Title,F),
  new_console_in(F,Query,L,C,Console),
  show(F).
  
new_console_in(Container,Query,Rows,Cols, console(Input,Output,Hub)):-
  new_panel(Container,border,Parent),
  set_direction(Parent,'Center'),
  new_text(Parent,'',Rows,Cols,Output), % output !!!
  set_direction(Parent,'North'),

  new_panel(Parent,border,Panel),
  set_direction(Panel,'West'),
  new_label(Panel,'?-',Label),
  set_direction(Panel,'Center'),
  new_text(Panel,Query,1,Cols,Input), % input
  set_direction(Panel,'East'),
  
  % input+output+Hub?
  hub(Hub),
  %new_button(Panel,'Run',do_input_action(Input,Output),Button),
  new_button(Panel,'Run',do_read_text_action(Input,Hub),Button),
  
  make_blue(Blue),
  set_fg(Input,Blue),
  make_black(Black),
  set_fg(Label,Black),
  set_fg(Button,Black),
  make_light_blue(LB),
  set_bg(Button,LB),
  set_bg(Label,LB).
 
do_input_action(Content,Input,Output):-do_input_action(call,Content,Input,Output).

do_input_action(Closure,Content,Input,Output):-
  make_gray(Gray),
  set_bg(Input,Gray),
  set_text(Input,Content),
  atom_codes(NL,[10]),
  atom_concat('?- ',Content,QS),
  add_text(Output,NL),
  add_text(Output,QS),
  add_text(Output,NL),
   
  %traceln('-------before'),cnl,
  
  ( atom_to_term(Content,G,NVs)->do_console_action(call(Closure,G),NVs,Output,NL)
  ; gui_exception(Output,NL,'syntax_error',Content,fail)
  ),
  
  %traceln('-----after'),cnl,
  
  make_white(White),
  set_bg(Input,White).
  

do_console_action(G,NVs,Output,NL):-
  (NVs=[]->
    (gui_topcall(Output,NL,G)->A='true.'
    ; A='fail.'
    ),
    add_text(Output,A),
    add_text(Output,NL)
  ; 
    foreach(gui_topcall(Output,NL,G),show_vars_in(Output,NVs,NL)),
    add_text(Output,'no (more) answers.'),
    add_text(Output,NL)
  ).
  
gui_topcall(Output,Goal):-  
  atom_codes(NL,[10]),
  gui_topcall(Output,NL,Goal).
   
gui_topcall(Output,NL,Goal):-
  %catch((Goal,stop),E,traceln(E)).
  catch(topcall(Goal),E,gui_exception(Output,NL,E,Goal,fail)).

to_gui_io(Device):-
  % traceln('GuiIO'(Device)),
  to_gui_io(Device,_).

to_stdio:-stdio(IO),set_input(IO),set_output(IO).

to_gui_io(console(Input,Output,Hub),GuiIO):-!,
 to_gui_io(Input,Output,Hub, GuiIO).
to_gui_io(Output,GuiIO):-
 Input=Output,
 hub(Hub),
 to_gui_io(Input,Output,Hub,GuiIO).

to_gui_io(_,'$null',_,IO):-!,stdio(IO). 
to_gui_io(Input,Output,Hub, GuiIO):-
  %new_java_object('gui.GuiIO'('?:',Input,Output,Hub),IO),
  new_gui_io(Input,Output,Hub, GuiIO),
  set_output(GuiIO),
  set_input(GuiIO).
  
gui_exception(Output,NL,E,_Goal,Finally):-  
  swrite(E,SE),
  add_text(Output,'*** '),add_text(Output,SE),add_text(Output,NL),
  % swrite(Goal,SG),
  % add_text(Output,'in ==> '),add_text(Output,SG),add_text(Output,NL),
  Finally.
   
show_vars_in(Output,NVs,NL):-
  foreach(
    member(NV,NVs),
    show_one_var_in(Output,NV,NL)
  ),
  add_text(Output,(';')),
  add_text(Output,NL).
  
show_one_var_in(Output,N-Val,NL):-
  add_text(Output,N),
  add_text(Output,' = '),
  swrite(Val,S),
  %traceln('!!!add_text'(S)),
  add_text(Output,S),
  % add_text(Output,(',')),
  add_text(Output,NL).



/* Prolog Dialog Box - implemented using Hubs - to synchronize consumer and producer threads*/
dialog(Q,A):-dialog(Q,20,100,A).

dialog(Q,WhereX,WhereY,A):-
  dialog(Q,yes,no,WhereX,WhereY,200,50,A).

dialog(Q,Y,N,WhereX,WhereY,SizeX,SizeY,A):-
   new_frame('',grid(1,1),0,F),
   move(F,WhereX,WhereY),
   resize(F,SizeX,SizeY),
   dialog_in(F,Q,Y,N,A),
   destroy(F).

dialog_in(Parent,Q,A):-
   dialog_in(Parent,Q,yes,no,A).

dialog_in(Parent,Q,Y,N,A):-
   new_panel(Parent,border,F),
   set_direction(F,'Center'),
   new_label(F,Q,_),
   hub(H),
   set_direction(F,'East'),
   new_panel(F,grid(1,2),P),
   new_button(P,Y,hub_put(H,Y),_),
   new_button(P,N, hub_put(H,N),_),
   show(Parent),
   hub_collect(H,R),
   destroy(F),
   hub_stop(H), % should be last
   A=R.

/* reads a string from a new box - from which sread can be used
   to extract Prolog terms */
      
gui_readln(StringRead):-
  gui_readln(gui_read_once,StringRead).

gui_readln(Operation,StringRead):-
   new_frame('',grid(1,1),0,F),resize(F,200,50),
   read_in(F,'>','Read',Operation,StringRead),
   destroy(F).
  
%gui_console:-gui_readln(gui_read_loop,_StringRead).
 
gui_console:-
   new_frame('Prolog Console',grid(1,1),0,F),resize(F,800,50),
   read_in(F,'?-','Run',gui_read_loop,_StringRead),
   destroy(F).
     
read_in(Container,Prompt,ActionName,Operation,StringRead):-
  read_in(Container,Prompt,ActionName,'',0,0,Operation, StringRead).
  
read_in(Parent, Prompt,ActionName,OldText, Rows,Cols, Operation, StringRead):-
  new_panel(Parent,border,Container),
  new_panel(Container,border,Panel),
  set_direction(Panel,'West'),
  new_label(Panel,Prompt,Label),
  set_direction(Panel,'Center'),
  new_text(Panel,OldText,Rows,Cols,Input), % input
  set_direction(Panel,'East'),
  
  hub(Hub),
  new_button(Panel,ActionName,do_read_text_action(Input,Hub),Button),
  
  make_blue(Blue),
  set_fg(Input,Blue),
  make_black(Black),
  set_fg(Label,Black),
  set_fg(Button,Black),
  make_light_blue(LB),
  set_bg(Button,LB),
  set_bg(Label,LB),
  show(Parent),
  
  call(Operation,Hub,Input,Result), 
  
  destroy(Container),
  hub_stop(Hub),
  StringRead=Result.
         
do_read_text_action(Text,Hub):-
  make_gray(Gray),
  get_text(Text,Content),
  set_bg(Text,Gray),
  set_text(Text,Content),
  hub_put(Hub,Content). 

gui_read_once(Hub,_, Result):-hub_collect(Hub,Result).
   
gui_read_loop(Hub,Input, End):-
  make_white(White),
  repeat,
    hub_collect(Hub,Line),
    set_bg(Input,White),
    ( Line == 'halt.' -> finalize_frame 
    ; atom_to_term(Line,T,Vs),
      call(T),
        println(Vs),
      fail
    ),
    !,
    End=done.
    
new_editor:-
  new_frame(F),
  new_editor(F,_),
  show(F).

/*    
edit(File0):-
  find_file(File0,File),
  new_frame(F),
  %new_file_editor(F,Editor),
  new_ide(F,'',_Output,Editor),
  load_to_text_area(File,Editor),
  show(F).
*/

new_editor(Container):-new_editor(Container,_).

new_editor(Container,Editor):-
  new_editor(Container,'',Editor).

new_editor(Container,OldText,Editor):-
  new_editor(Container,OldText,0,0,Editor).

new_editor(Container,OldText,Rows,Cols,  Input):-
  new_editor(prolog,Container,OldText,Rows,Cols,  Input).


new_text_editor:-
  current_dir(Dir),
  new_text_editor_at(Dir).
  
new_text_editor_at(Dir):-
  new_file_dialog(0,Dir,FName),
  ( FName\==no,file2string(FName,OldText),not_null(OldText)->true
  ; OldText=''
  ),
  new_text_editor_with(OldText).

new_text_editor_with(OldText):-
  new_frame(F),
  new_text_editor(F,OldText,_),
  show(F).
        
new_text_editor(Container,OldText,Editor):-
  new_panel(Container,border,Panel),
  set_direction(Panel,'Center'),
  new_text_editor(Panel,OldText,0,0,Editor),
  set_direction(Panel,'North'),
  M2 is -2,
  new_buttons(Panel, [
    'New'=>clear_action(Editor),
    'Load'=>load_action(Editor),
    '+'=>font_action(Editor,inc_font_size(2)),
    '-'=>font_action(Editor,inc_font_size(M2)),
    'Save'=>bg(save_action(Editor)),
    'Exit'=>destroy(Container)
  ]).
  
new_text_editor(Container,OldText,Rows,Cols,  Input):-
  new_editor(text,Container,OldText,Rows,Cols,  Input).
  
new_editor(PrologOrText,Container,OldText,Rows,Cols,  Input):-
  make_blue(Blue),
  make_black(Black),
  make_light_blue(LB),
  new_panel(Container,border,Panel),
  set_direction(Panel,'North'),
  new_label(Panel,'Editor',Label),
  set_fg(Label,Black),set_bg(Label,LB),
  set_direction(Panel,'Center'),
  new_text(Panel,OldText,Rows,Cols,Input), % input
  set_fg(Input,Blue),
  set_direction(Panel,'South'),
  % output can be a PWriter built around any TextSink
  (PrologOrText=prolog ->
    new_button(Panel,'Reconsult',
               do_text_action(Input,'reconsult_string'),Button), 
    set_fg(Button,Black),set_bg(Button,LB)
  ; true
  ).
  
do_text_action(Text,Action):-
  make_gray(Gray),
  get_text(Text,Content),
  set_bg(Text,Gray),
  set_text(Text,Content),
  call(Action,Content),
  make_white(White),
  set_bg(Text,White).

%% reconsult_string(String): reconsults clauses by parsing string
reconsult_string(String):-
  reconsult('$str'(String)).
  
   
/* Prolog Editor - squeeze to small default initial size size to
   fit on PocketPCs - resize at will ! */   

new_file_editor:-
  new_frame(F),
  new_file_editor(F,_),
  show(F).
        
new_file_editor(Frame,Editor):-
   hub(Hub),
   new_file_editor(Hub,Frame,Editor).
        
new_file_editor(Hub,Container,Editor):-
  new_panel(Container,border,Panel),
  set_direction(Panel,'Center'),
  new_editor(Panel,Editor),
  set_direction(Panel,'North'),
  M2 is -2,
  new_buttons(Panel, [
    'New'=>clear_action(Editor),
    'Load'=>load_action(Editor),
    '+'=>font_action(Editor,inc_font_size(2)),
    '-'=>font_action(Editor,inc_font_size(M2)),
    'Save'=>call(save_action(Editor)),
    'Exit'=>hub_put(Hub,exit) %,exit_action(Hub,Frame)
  ]).

exit_action(Hub,Frame):-
  println(exiting),
  to_stdio,
  stop(Hub),
  destroy(Frame).

font_action(Text,Action):-
   get_text(Text,Content),
   Action,
   set_text(Text,Content).
        
clear_action(Text):-
  make_white(White),
  set_bg(Text,White),
  set_text(Text,'').

load_action(Text):-
  new_file_dialog(0,File),
  not_null(File),File\==no,
  !,
  load_to_text_area(File,Text).
load_action(_).

load_to_text_area(File,Text):-
  file2string(File,S),
  make_white(White),
  set_bg(Text,White),
  set_text(Text,S).
  
save_action(Text):-
  new_file_dialog(1,File),
  not_null(File),
  !,
  get_text(Text,Content),
  string2file(Content,File),
  make_gray(Gray),
  set_bg(Text,Gray).
save_action(_).
 
new_buttons(Parent,Xs):-
  length(Xs,N),
  new_panel(Parent,grid(1,N),Panel),
  new_buttons_in(Xs,Panel).

new_buttons_in([],_).
new_buttons_in([Name=>Action|Ps],Panel):-
  % println(here=Name),
  new_button(Panel,Name,Action,_Button),
  new_buttons_in(Ps,Panel).



/* Prolog IDE - contains simple file editor and console */

ide:-ide('Prolog IDE').

ide(Name):-ide(Name,'println(hello).').

ide(Name,Query):-
  new_frame(Name,F),
  new_ide(F,Query).

new_ide(Name):-ide(Name,'println(please(enter,a,query)).').

new_ide(Frame,Query):-
  new_panel(Frame,grid(2,1),IDE),
  new_console_in(IDE,Query,10,20,Console),
  arg(3,Console,Hub),
  new_file_editor(Hub,IDE,_EditArea),
  show(Frame),
  run_console(Frame,Console).


% DEPRECATED


gui_write(GuiName,T):-
   GuiName==>Output,
   to_string(T,S),
   invoke_java_method(Output,append_text(S),_).

gui_print(GuiName,T):-gui_write(GuiName,T).

gui_println(GuiName,T):-gui_write(GuiName,T),gui_nl(GuiName).

gui_put_code(GuiName,Code):-
  GuiName==>Output,
  invoke_java_method(Output,appendCode(Code),_).
   
gui_nl(GuiName):-
   GuiName==>Output,
   invoke_java_method(Output,appendNL,_).


% compatibility with old GUI - TODO 
             
/*             
% RLI eanbled GUI agents  %

rli_ide(WinName,PortName,InitialGoal):-
  Gui=new_ide,
  run_rli_gui(Gui,WinName,PortName,InitialGoal).

rli_console(WinName,PortName,InitialGoal):-
  Gui=new_console_in,
  run_rli_gui(Gui,WinName,PortName,InitialGoal).

% ////
run_rli_gui(Gui,WinName,PortName,InitialGoal):-
  new_frame(WinName,F),
  RLIGoal=rli_call(PortName,InitialGoal),
  to_string(RLIGoal,SGoal),
  call(Gui,F,SGoal,OutputArea),
  show(F),
  process_console_query(RLIGoal,OutputArea).


process_console_query(rli_call(Port,Query),OutputArea):-
  !,
  to_gui_io(OutputArea,PWriter),
  % println(here=PWriter),
  rli_start_server(Port,PWriter),
  sleep_ms(50),
  rli_wait(Port),
  rli_call_nobind(Port,Query).
process_console_query(call(Query),OutputArea):-
  !,
  gui_topcall(OutputArea,Query).
process_console_query(_Query,_OutputArea).



% ////  
swing_bg(Goal):-
  to_runnable(and(Goal,fail),Runnable),
  call_java_class_method(
    'jgui.Start',
     invokeLater(Runnable),
     _
  ).
  

vdesktop:-call_java_class_method('agentgui.Main',startgui,_).

econsole:-launch_external(console).

iconsole:-launch_internal(console).

egui:-
 gvar_set(gui,awt),
 gvar_set(desktop,real).

igui:-
 gvar_set(gui,swing),
 gvar_set(desktop,virtual).
  
launch_external(Goal):-launch_in_gui(egui,Goal).

launch_internal(Goal):-launch_in_gui(igui,Goal).

launch_in_gui(Where,Goal):-
  gvar_get(gui,GUI),
  gvar_get(desktop,DT),
  Where,
  (call(Goal)->true ; println(failed_to_launch_in_gui=Goal)),
  gvar_set(gui,GUI),
  gvar_set(desktop,DT).
  
  
% direct access to underlying TextSink - for visual displays only

set_text(String):-get_text_sink(Handle),set_text(Handle,String).

add_text(String):-get_text_sink(Handle),add_text(Handle,String).

get_text(String):-get_text_sink(Handle),get_text(Handle,String).

clear_text:-set_text('').

clear_text(Component):-set_text(Component,'').

% end of TextSink API

set_thread_wait(Ms):-call_java_class_method('jgui.Start',set_thread_wait(Ms),_).

set_max_display(Max):-
   call_java_class_method('jgui.Displayer',set_max_display(Max),_).
    
new_inner_frame(Title,Frame):-
  call_java_class_method('agentgui.Main',new_inner_frame(Title),Frame).

*/  