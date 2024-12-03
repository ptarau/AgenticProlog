/*
l_agent(Name):-l_console(Name).
     
l_console(Name):-
  (is_agent(Name)->true;Name@init),
  Mes='println(\'type exit to quit\')',
  i_console(Name,Frame,Hub),
  init_s_console(Console),
  run_console('@'(Name),Frame,Console).
*/  

i_console(Name):-  
  i_console(Name,Frame,Hub),
  Name<==i_console(Frame,Hub).
  
i_console(Name,Frame,Hub):-
  traceln(starting(i_console,'type exit to quit')),
  %atom_concat('INPUT DISABLED. PORT=',Port,Mes),
  Mes='println(hello).',
  new_console(Name,Mes,10,20, Frame,Console),
  arg(3,Console,Hub),
  Clone=1,Source=no,
  Goal=run_console(call,Frame,Console),
  new_logic_thread(Hub,ignore,Goal,Clone,Source),
  traceln(running(i_console)).
  /*
  fail,
  ask_interactor(Hub,Answer),
  traceln(Answer),
  stop_interactor(Hub),
  destroy(Frame).
  */
 
i_console_stop(Name):-
  Name==>i_console(Frame,Hub),
  gvar_remove(Name),
  to_stdio,
  tell_interactor(Hub,exit),
  destroy(Frame),
  stop(Hub).
    
i_ask(Name,ActionQuery):-
   Name==>i_console(_Frame,Hub),
   tell_interactor(Hub,ActionQuery).
    
