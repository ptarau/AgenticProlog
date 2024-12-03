package gui;

import java.awt.TextArea;
import java.awt.event.KeyEvent;

public class PrologText extends TextArea {
  PrologText(){
    GuiBuiltins.setLooks(this);
  }
  
  /*
  public void appendText(String s) { // add_text in Prolog
     append_text(s);
  }
  */

  public void append_text(Object s) {
    // System.out.println("!!!append_text:"+s);
    // GuiBuiltins.setLooks(this);
    // super.appendText(s);
    super.append(s.toString());
  }
  
  public void appendNL() {
    append_text("\n");
  }
  
  public void appendCode(int c) {
    append_text(""+(char)c);
  }
  
  public void setText(String s) { // set_text in Prolog
    GuiBuiltins.setLooks(this);
    super.setText(s);
  }
  
  PrologText(String oldText){
    super(oldText,GuiBuiltins.defRows,GuiBuiltins.defCols,
        SCROLLBARS_VERTICAL_ONLY);
    validate();
    // Interact.println("creating text area: "+this);
  }
  
  /*
  public boolean handleEvent(Event event) {
    if (event.id==Event.KEY_PRESS) {
      GuiBuiltins.setColors(this);
    }
    return super.handleEvent(event);
  }
  */

  public void processKeyEvent(KeyEvent e) {
    GuiBuiltins.setColors(this);
  }
  
  public void removeNotify() {
    super.removeNotify();
  }
  
  // public void setSize(int x,int y) {
  // Interact.println("resizing text area: "+this);
  // super.setSize(x,y);
  // }
}
