package gui;

import java.io.IOException;

import vm.extensions.Hub;
import vm.extensions.IOInteractor;
import vm.logic.Interactor;

public class GuiIO extends IOInteractor {// ConsoleIO {
  private static final long serialVersionUID=222L;
  
  public String readln() throws IOException {
    hub.ask_interactor(); // can be made to send EOF
    return input.getText();
  }
  
  public static Interactor new_interactor(String prompt,PrologText input,
      PrologText output,Hub hub) {
    return new GuiIO(prompt,input,output,hub);
  }
  
  PrologText input;
  
  PrologText output;
  
  Hub hub;
  
  public GuiIO(Object prompt,PrologText input,PrologText output,Hub hub){
    super(prompt);
    this.input=input;
    this.output=output;
    this.hub=hub;
  }
  
  synchronized public void println(Object O) throws IOException {
    print(O);
    output.appendNL();
  }
  
  public void print(Object O) throws IOException {
    if(null==O)
      O="$null";
    output.append_text(O.toString());
  }
  
  synchronized public void prompt() throws IOException {
    print(initiator.toString());
  }
}
