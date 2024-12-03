package compat;

import vm.logic.Stateful;

public interface TextSink extends Stateful {
  
  // public void open();
  
  public void append_text(String s);
  
  // public void close();
}
