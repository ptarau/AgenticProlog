AGENTS:

Agents can be created with new_agent(Name)
and called with
 
Name:SimpleGoal
 
Their state is locally kept with var<=value, var=>value.
 
 Goals like
 
 alice:assert(a(88)) 
 
are redirected to the agent - possibly over the network.

Various types of agents can be freely mixed.

Example of interaction:

Window1:

?-start_broker.

Window 2 - try

1 main ?- new_s_agent(alice).

4 main ?-bob:hi.

5 main ?-alice:assert(a(88)).

6 main ?-alice:agent_call(a(X)).

7 main ?-stop_agent(bob).

8 main ?-stop_agent(alice).

Window 3: - try

2 ?-new_m_agent(bob).

3 alice:hi

See code in broker.pl for more.
