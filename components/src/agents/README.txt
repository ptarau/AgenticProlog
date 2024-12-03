Spaces are just mappings to rli ports.

Agents are mapped to db_* predicates.
They can visit spaces where, after that, they
might aquire followers. Agents
broadcast their db_ updates to all the
places they visit.

Publishing happens on channels, possibly
mapped to rli ports. Variants exist for
broadcasting to each local or remote
subscriber content posted on a channel.

Coordinators control multiple coroutining
engines using the Linda protocol. They
can be used to handle suspension/resumption
of multiple engines with in/out operations.

Here is an example running exercising some of
the operations of this API:

WINDOW 1

main ?- start_space(boo)
true.
main ?- listings

% joe: like / 1.
like(beer).

% global variables

true.
main ?- alice@[joe].
true.
main ?- alice@like(X)   
X = beer

No (more) answers.

main ?- rli_start_publising(news).
[main, EXT:PROT:ENG:0:] : error(undefined_goal_called_with_indexed_database($), rli_start_publising(news))
main ?- rli_start_publishing(news).
indexing(time_of(1,1,0))
true.
main ?- rli_consume(alice,news,X)
X = dog(died)

No (more) answers.

main ?- rli_consume(alice,news,X)
[main, EXT:PROT:ENG:0:] : remote_error_at(localhost, news, error(undefined_goal_called_with_indexed_database($), (_0 :- consume_new(alice, news, _0))))
main ?- 

WINDOW 2

main ?- joe@visit(boo).
true.
main ?- joe@visit(bee).
true.
main ?- joe@assert(like(beer)).
true.
main ?- rli_publish(news,dog(died)).
true.
main ?- 

WINDOW 3

main ?- start_space(bee).
true.
main ?- listings

% joe: like / 1.
like(beer).

% global variables

true.
main ?- rli_consume(joe,news,X)
X = dog(died)

No (more) answers.

--- cooperative Linda

main ?- test_coordinator
indexing(waiting(1,0))
coop_out = f(3)
coop_out = f(2)
coop_out = f(0)
coop_in = f(0)
coop_out = f(1)
coop_in = f(2)
coop_in = f(1)
coop_in = f(3)
true.

SPACES
