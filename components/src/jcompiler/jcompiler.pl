jctest:-
  println(hello),
  new_compile('src/jcompiler/test.pl').


% API

new_compile(F):-
   new_java_class('jcompiler.Compiler',Class),
   current_engine(E),
   invoke_java_method(Class,jcompile(F,E),Result),
   println(Result).
