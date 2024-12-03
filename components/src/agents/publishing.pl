
% TODO

rli_start_publishing(Channel):-
  rli_start_publishing(Channel,[]).

%% rli_start_publishing(Channel,ContentIndexings): starts RLI enabled publishing
rli_start_publishing(Channel,ContentIndexings):-
  rli_start_server(Channel),
  rli_wait(Channel),
  init_publishing(ContentIndexings).

rli_publish(Channel,Content):-rli_publish(localhost,Channel,Content).
  
%% rli_publish(Host,Channel,Content): publishes Content on Channel at Host
rli_publish(Host,Channel,Content):-
  rli_call(Host,Channel,publish(Channel,Content),_).

rli_consume(Subscriber,Channel,Content):-
  rli_consume(Subscriber,localhost,Channel,Content).
  
%% rli_consume(Subscriber,Host,Channel,Content): consumes Content throug RLI as Subscriber   
rli_consume(Subscriber,Host,Channel,Content):-
  rli_call(Host,Channel,
    (Content:-consume_new(Subscriber,Channel,Content)),
    the(Content)
  ).
  
rli_peek_at_published(Channel,ContentPattern, Matches):-
  rli_peek_at_published(localhost,Channel,ContentPattern, Matches).

%% rli_peek_at_published(Host,Channel,ContentPattern, Matches): associatively finds all matching patterns on Channel
rli_peek_at_published(Host,Channel,ContentPattern, Matches):-
  rli_call(Host,Channel,
     (Matches:-peek_at_published(Channel,ContentPattern, Matches)),
     the(Matches)
  ).
  
%% publishing API: induces no suspension - can be used with s_call and open_dialog, close_dialog
% - confusing: sports@publish(wins(bills))
%% publish(Channel,Content):
publish(Channel,Content):-
  % make sure you index Content before using this
  increment_time_of('$publishing',Channel,T),
  db_assert(Channel,(Content:-published_at(T))).

%% consume_new(Subscriber,Channel,Content): reads next message on Channel - Content expected to be a free variable
consume_new(Subscriber,Channel,Content):-
  var(Content),
  !,
  get_time_of(Channel,Subscriber,T1),
  db_clause(Channel,Content,published_at(TP)), 
  T1=<TP,
  T2 is T1+1,
  set_time_of(Channel,Subscriber,T2).
consume_new(Subscriber,Channel,Content):-
  errmes(should_have_a_free_var_as_arg_3,consume_new(Subscriber,Channel,Content)).

%% peek_at_published(ContentPattern, Matches): searches for published content independently of having read it alredy  
 
peek_at_published(Channel,ContentPattern, Matches):-
  findall(ContentPattern, db_clause(Channel,ContentPattern,_),Matches).
      
%% init_publishing: sets up default initial assumptions for publishing  
init_publishing:-init_publishing([]).

%% init_publishing(ContentIndexings): sets up indexing using list of ContentIndexings of the form pred(1/0,1/0...)
init_publishing(ContentIndexings):-
  index(time_of(1,1,0)),
  maplist(index,ContentIndexings).

%% clean_up_publishing: removes everything published as well as tracking of subscribers
clean_up_publishing:-
  ( db_clause(global_time,time_of('$publishing',Key,_),_),
    db_clear(Key),
    fail
  ; true
  ),
  db_clear(global_time).
  

  
clear_channel(Channel):-
  db_clear(Channel),
  remove_time_of('$publishing',Channel).
  
clear_subscriber(Subscriber):-
  remove_time_of(_,Subscriber).
  
increment_time_of(Role,Key,T1):-
  db_retract1(global_time,time_of(Role,Key,T)),
  !,
  T1 is T+1,
  db_assert(global_time,time_of(Role,Key,T1)).
increment_time_of(Role,Key,0):-
  db_assert(global_time,time_of(Role,Key,0)).

remove_time_of(Role,Key):-db_retractall(global_time,time_of(Role,Key,_)).

set_time_of(Role,Key,T):-
  nonvar(Key),
  remove_time_of(Role,Key),
  db_assert(global_time,time_of(Role,Key,T)).
  
get_time_of(Role,Key,R):-
  db_clause(global_time,time_of(Role,Key,T),_),
  !,
  T>=0,
  R=T.
get_time_of(Role,Key,0):-
  db_assert(global_time,time_of(Role,Key,0)).


% change consume_new->consume
pubtest:-
  init_publishing([wins(1),loses(1)]),
  maplist(show_goal,
  [
  publish(sports,wins(rangers)),
  publish(politics,loses(meg)),
  publish(sports,loses(bills)),
  publish(sports,wins(cowboys)),
  publish(politics,wins(rand)),
  consume_new(joe,sports,_),
  consume_new(mary,sports,_),
  consume_new(joe,sports,_),
  consume_new(joe,politics,_),
  consume_new(joe,politics,_),
  consume_new(mary,sports,_)

  ]),
  println('FINALY'),
  listings,
  clean_up_publishing.
 
show_goal(G):-
  G,
  !,
  println(G).
show_goal(G):-
  println('***failed'(G)).