% additional networking

To launch the HTTP server type:

psa.sh

(or the equivalent from the Prolog prompt.)

Then click on LAUNCH.html

to try out the default psa agent.

Customize by editing psa_step.pl (quite easy) and possibly
post_method_handler in psa_handler.pl (somewhat more
complex task, make sure this predicate never fails).
Currently the template output.html contains to
PHP-style fields

{{?answer}}

{{?history}}

psa_step fills out "answer" and "history" is accumulated
in psa_handler.pl in the dynamic database.

Note:

The server has been simplified - it is now single-threaded and
likely to run forever, even with large data requests. Each query
is handled by a separate prolog+engine so errors should not
crash the server (unless they take the process down). Files
are served direcly from Java with no overhead to Prolog.