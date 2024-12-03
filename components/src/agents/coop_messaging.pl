% messaging - expressed in terms of cooperative Linda protocol

send_msg(From,To,Msg):-
  coop_out(msg(From,To,Msg)).

handle_msg(From,To,Msg):-
  coop_in(msg(From,To,Msg)).