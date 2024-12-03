Helper module - provides quick help from inside Prolog.

Type when running all components embedded in lprolog.jar:

?-make_help.

It creates helpData.pl that will, at the next call to ?-go.
end up embedded in lprolog.jar.

Type

?-help(Substring).

or

?-helps.

for seeing all the help system.

