package compat;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;

import vm.logic.Interact;
import vm.logic.Stateful;

class GenericWriter extends PrintWriter {
  //
  public GenericWriter(OutputStream f){
    // super(f,true); // flush automatically on NL
    super(Interact.tryEncoding(f),true); // flush automatically on
    // NL
  }
  
  public GenericWriter(String fileName) throws IOException{
    super(Interact.safeFileWriter(fileName));
  }
  
  public GenericWriter(){
    // super(Interact.getStdOutput(),true);
    this(System.out);
  }
}

/**
 *  Basic Prolog char writer
 */

public class PrologWriter extends GenericWriter implements Stateful {
  /**
   * allows virtualizing output to go to something like a GUI element
   * clearly there's no file in this case - the extender should
   * provide some write and newLine methods that append to a window
   * it could also be used to do nothing at all - and disable any
   * output by implementing a "do nothing" PrologWriter extension
  */
  
  public TextSink textSink;
  
  public PrologWriter(TextSink textSink){
    this.textSink=textSink;
  }
  
  public TextSink getTextSink() {
    return this.textSink;
  }
  
  public PrologWriter(OutputStream f){
    super(f);
  }
  
  public PrologWriter(String fileName) throws IOException{
    this(new FileOutputStream(fileName));
  }
  
  public final void super_write(int c) {
    if('\n'==c)
      super.flush();
    super.write((char)c);
  }
  
  public void write(int c) {
    // System.err.println(Interact.NL+this+"write => <"+(char)c+">");
    if(!(Interact.verbosity>0))
      return;
    super_write(c);
    return;
  }
  
  public void flush() {
    if(!(Interact.verbosity>0))
      return;
    super.flush();
    return;
  }
  
  public void print(String s) {
    // System.err.println(Interact.NL+this+"print => <"+s+">");
    if(!(Interact.verbosity>0))
      return;
    super.print(s);
    if(s.indexOf('\n')>0)
      super.flush();
    return;
  }
  
  public void println(String s) {
    print(s+Interact.NL);
  }
  
  public void println() {
    print(""+Interact.NL);
  }
  
}
