% stream I/O with TEXT FILES

fopen(Fname,'r',r(Reader)):-
  call_java_class_method('compat.Tools',toReader(Fname),Reader).
fopen(Fname,'w',w(Writer)):-
  call_java_class_method('compat.Tools',toWriter(Fname,0),Writer).
fopen(Fname,'a',w(Writer)):-
  call_java_class_method('compat.Tools',toWriter(Fname,1),Writer).

fgetc(r(Reader),C):-invoke_java_method(Reader,read,C).

fclose(r(Reader)):-invoke_java_method(Reader,close,_).
fclose(w(Writer)):-invoke_java_method(Writer,close,_).

fputc(w(Writer),C):-call_java_class_method('compat.Tools',fputc(Writer,C),_).

f_nl(F):-fputc(F,10).

fprintln(w(Writer),T):-term_to_atom(T,S),invoke_java_method(Writer,write(S),_),f_nl(w(Writer)).

/*
fprintf(w(Writer),Format,ArgList):-
  fix_format_arg(Format,FormatSpec),
  list_to_array(ArgList,Args),
  invoke_java_method(Writer,printf(FormatSpec,Args),_).

fix_format_arg(Format,Fixed):-atom(Format),!,Fixed=Format.
fix_format_arg(ListFormat,Fixed):-atom_codes(Fixed,ListFormat).

fprintf_test:-
  fopen('temp.txt','w',F),
  X is 7/3,
  fprintf(F,"%s %g",[hello,X]),f_nl(F),
  fclose(F),
  fopen('temp.txt','r',F1),
  repeat,
    fgetc(F1,C),
    ( C=:= -1 -> !
    ; put(C),
      fail
    ),
    fclose(F1).
*/

% fct:-fcopy_test('temp.txt','temp1.txt').

% not meant to work on binary (byte) files
fcopy_test(From,To):-
  (exists_file(To)->delete_file(To);true),
  fopen(From,'r',Input),
  fopen(To,'w',Output),
  repeat,
    fgetc(Input,C),
    ( C =:= -1 -> !
    ; fputc(Output,C),
      fail
    ),
  fclose(Input),
  fclose(Output).

rfopen(FName,FHandle):-
  new_java_object('java.io.RandomAccessFile'(FName,'rw'),FHandle).

rfcall(FHandle,MethArgs,Result):-
  invoke_java_method(FHandle,MethArgs,Result).

rfget(FHandle,Byte):-rfcall(FHandle,read,Byte).

rfseek(FHandle,NBytes):-rfcall(FHandle,seek(NBytes),_).

rfput(FHandle,Byte):-rfcall(FHandle,writeByte(Byte),_).

rfskip(FHandle,NBytes):-rfcall(FHandle,skipBytes(NBytes),_).

rfclose(FHandle):-rfcall(FHandle,close,_).

rfappend(FHandle,Byte):-
  rfcall(FHandle,length,L),
  rfseek(FHandle,L),
  rfput(FHandle,Byte).
  
rftest:-
  rfopen('temp1.txt',F),
  rfseek(F,0),
  [A,B,C]="xyz",
  rfput(F,A),
  rfappend(F,B),
  rfappend(F,C),
  rfclose(F).
   
file_slice_to_list(File,From,Length):-
  rfopen(File,F),
  rfseek(F,From),
  rfclose(F).
  
  
  
% end

