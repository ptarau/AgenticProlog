%term_decoder(T,T).
%term_encoder(T,T).

default_http_port(8001).
default_http_root(D):-current_dir(D).

run_http_server:-
  default_http_port(Port),
  run_http_server(Port).
  
run_http_server(Port):-
  default_http_root(Root),
  run_http_server(Port,Root).

run_http_server(Port,Root):-
  println(starting_http_server_on(port(Port),www_root(Root))),
  current_engine(E),
  new_java_class('net.HttpService',C),
  invoke_java_method(C,run_http_server(Port,Root,E),_).

       
% client side RPCs

new_client(Host,Port,Client):-new_client(Host,Port,1,Client).

new_quiet_client(Host,Port,Client):-
  new_client(Host,Port,0,Client),
  invoke_java_method(Client,connect,TF),
  is_true(TF).

new_client(Host,Port,TryConnect,Client):-
  new_java_object('vm.extensions.Transport'(Host,Port,TryConnect),Client).

disconnect(ServiceOrClient):-
  invoke_java_method(ServiceOrClient,disconnect,_),
  delete_java_object(ServiceOrClient).

remote_ping(Port):-remote_ping(localhost,Port).

%% remote_ping(Host,Port) : true if classic server at Host,Port is up and running
remote_ping(Host,Port):-
  new_quiet_client(Host,Port,Client),
  ask_service(Client,_,true,none,_),
  disconnect(Client).

remote_wait(Port):-remote_wait(localhost,Port).

%% remote_wait(Host,Port): waits until server on Host:Port is on
remote_wait(Host,Port):-remote_ping(Host,Port),!.
remote_wait(Host,Port):-sleep_ms(200),remote_wait(Host,Port).

discontinue(Service):-
  invoke_java_method(Service,discontinue,_).
  
ask_query_get_answer(Client,QW,A):-
  %traceln(asking(xQW)),
  write_to(Client,QW),
  %traceln(written(xQW)),
  read_from(Client,A),
  %traceln(getting_back(xA)),
  not_null(A).


ask_service(Client,X,G,W,R):-
  encode_term(the(X,G,W),QW),
  ask_query_get_answer(Client,QW,A),
  decode_term(A,T),
  % delete_java_object(QW),
  % delete_java_object(A),
  !,
  R=T.
ask_service(_,_,_,_,no).
    
ask_server(H,P,X,G,W,R):-
  new_client(H,P,Client),      
  ask_service(Client,X,G,W,R),
  disconnect(Client).

remote_run(G):-remote_run(localhost,7001,G).

%% remote_run(H,P,G): runs G remotely on classic server at H,P - beware that it only handles small data !!!
remote_run(H,P,G):-remote_run(H,P,G,G,the(G)).

%% remote_run(H,P,X,G,R): runs a G remotely on classic server at H,P return R=the(X) or no if it fails
remote_run(H,P,X,G,R):-remote_run(H,P,X,G,none,R).

remote_run(H,P,X,G,W,R):-integer(P),P>0,!,ask_server(H,P,X,G,W,R).

new_server(Port,Server):-
  new_java_object('vm.extensions.Transport'(Port),Server).
   
new_service(Server,Service):-
  call_java_class_method('vm.extensions.Transport',newService(Server),Service),
  not_null(Service)
  ->true
; throw(unable_to_start_service_on_given_port).

/*
read_from(Service,Query):-
  invoke_java_method(Service,read_from,Query).

write_to(Service,Answer):-
  invoke_java_method(Service,write_to(Answer),_).
*/

read_from(Service,Query):-if_legacy,!,invoke_java_method(Service,read_from,Query).
read_from(Service,Query):-bundle_read(Service,Query).

write_to(Service,Answer):-if_legacy,!,invoke_java_method(Service,write_to(Answer),_).
write_to(Service,Answer):-bundle_write(Service,Answer).

bundle_read(Service,Query):-
  % current_engine(E),
  current_engine_object(E),
  invoke_java_method(Service,bundle_read(E),_),
  import_term(Query).

bundle_write(Service,Answer):-
  %current_engine(E),
  current_engine_object(E),
  export_term(Answer),
  invoke_java_method(Service,bundle_write(E),_).


% server side RPC handling
   
run_server:-run_server(7001).

%% run_server(Port): starts classic server on Port
run_server(Port):-
  run_server(Port,none).
   
run_server(Port,Password):-
  integer(Port),Port>0,
  !,
  new_server(Port,Server),
  not_null(Server),
  hub(Hub),
  Port<==Hub,
  repeat,
    ( new_service(Server,Service),not_null(Service)-> 
      true 
    ; !,
      fail
    ),
    %bg(handle_service(Service,Password)),
    X=ignore,
    G=handle_service(Service,Password),
    Clone=1,
    new_logic_thread(Hub,X,G,Clone),
  fail.
run_server(Port,Password):-
  println('Internal Server started on port'(Port)),
  in('$internal_server'(Port,Password)).


stop_server(Port):-
  Port==>Hub,
  stop(Hub).
  
stop_server:- 
  %println(server_stopped),
  true.
    
handle_service(Service,Password):-
  if(answer_one_query(Service,Password),true,true),
  disconnect(Service),
  fail.
 
 /*
 note: read_from can be optimize using
 export_term(T)
 followed a cognizant
 wrtite_to(Service) that picks up T
 - dually, for import_term + read_from
 */
answer_one_query(Service,Password):-
  % stat,nl,
  read_from(Service,QString),
  %traceln(got=xQString),
  not_null(QString),
  decode_term(QString,QTerm),
  %traceln(got=xQTerm),
  react_to(QTerm,Password,ATerm),
  %traceln(react_to=xATerm),
  % stat,println('----'),nl,
  encode_term(ATerm,AString),
  write_to(Service,AString),
  %traceln(written(xAString)),
  %traceln([sent=AString,qterm=QTerm]),ttynl,
  (arg(2,QTerm,stop_server)->discontinue(Service);true).


  
% defines how RPC requests are handled

react_to(Term,Password,Answer):-
  run_query_term(Term,Result,Password),
  !,
  Answer=the(Result).  
react_to(_,_,Answer):-
  Answer=no.

if_legacy:-current_prolog_flag(term_encoder,legacy).

decode_term(String,Term):-if_legacy,!,atom_to_term(String,Term).
decode_term(Term,Term).

encode_term(Term,String):-if_legacy,!,term_to_atom(Term,String).
encode_term(Term,Term).

%% bp_terms:: sets prolog_flag term_encoder in remote_run/run_server to send terms as strings that BinProlog can parse
bp_terms:-set_prolog_flag(term_encoder,legacy).

%% java_terms:: sets prolog_flag term_encoder in remote_run/run_server such that serialized terms are sent - avoiding parsing
java_terms:-set_prolog_flag(term_encoder,java).

% comment this out if you want compatibility with legacy client/server that parse strings
%term_encoder(T,T).
%term_decoder(T,T).

run_query_term(the(Answer,Goal,CPassword),Answer,SPassword):-call_here(CPassword,SPassword,Goal).
run_query_term(run(CPassword,Answer,Goal),Answer,SPassword):-call_here(CPassword,SPassword,Goal). % BinProlog compatibility?

% catch_once avoids leaking the engine used to run the goal
call_here(CP,SP,G):-CP==SP,!,call_here(G).
call_here(CP,_,G):-println(warning(wrong_password_for_query(G),passwd(CP))).

%call_here(G):-catch_once(topcall(G),Error,(println(error_in(G,Error)),fail)).

call_here(G):-topcall(G),!.

% for BinProlog compatibility

run(_,G,_):-println(unexpected_topcall(G)).


  
% end
  