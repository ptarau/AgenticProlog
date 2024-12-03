A typical run on any OS:

cd bin
java -jar ../lprolog.jar ../lprolog.jar
?-[nrev].
?-go.
?-halt.

On a Mac OS X, the Java version bootstraps with either (sgo - swipl based)
or (go - bp based) and then selfcompiles with lgo, creating lprolog.jar.
The same should work (may need small adaptations depending on shell) on any Unix/Linux.

 All programs in bin/progs run happily with it. The C version only
runs a subset - at this point pure Prolog + CUT. The plan is to
extend it using the Java implementation as a reference.

Here are some features of (version 0.4.0):

- complete Interactor API (as in the PADL'09 paper)
- Interactor based console and ISO compliant file IO
- new ISO compliant Prolog parser - full support for operators
- complete set of arithmetic operations - arbitrary size integers 
  and arbitrary precision decimals (see xbuiltins.pl+Xbuiltins.java)
- multiple code spaces (ready for clean agent programming)
- compile/consult to memory
- assert/retract =>,<= ==> <== global variables

Extensions planned to be added (in a modular way):

- Java GUI
- multi-threading
- connection with C-based emulator
- networking

Convention for third party extensions: add them to lib, then customize
the script "to_xjar" to embed them into prolog.jar together
with their license files. Flexible (i.e. Apache, BSD, LGPL) licensing 
is preferred and should be checked before using this mechanism.
