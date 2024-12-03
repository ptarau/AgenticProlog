package gui;

import java.io.IOException;

import vm.extensions.IOInteractor;
import vm.logic.Interactor;

public class GuiO extends IOInteractor {// ConsoleIO {
  private static final long serialVersionUID=222L;
  
  public static Interactor new_interactor(PrologText output) {
    return new GuiO(output);
  }
  
  PrologText output;
  
  public GuiO(PrologText output){
    super("?");
    this.output=output;
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
  }
}
