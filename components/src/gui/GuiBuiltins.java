package gui;

import java.awt.AWTEvent;
import java.awt.BorderLayout;
import java.awt.Button;
import java.awt.Canvas;
import java.awt.CardLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.Container;
import java.awt.FileDialog;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.Frame;
import java.awt.Graphics;
import java.awt.GridLayout;
import java.awt.Image;
import java.awt.Label;
import java.awt.LayoutManager;
import java.awt.Panel;
import java.awt.Toolkit;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowEvent;
import java.io.File;
import java.io.FilenameFilter;

import vm.extensions.Hub;
import vm.logic.Interact;
import vm.logic.Interactor;
import vm.logic.LogicInteractor;
import vm.logic.PrologException;
import vm.logic.Stateful;

/**
  Provides builtins for GUI programs.
  Called though Reflection from Prolog.
*/
public class GuiBuiltins implements Stateful {
  private static final long serialVersionUID=222L;
  
  public static int defX=640;
  
  public static int defY=480;
  
  public static int defRows=16;
  
  public static int defCols=24;
  
  public static int gapX=2;
  
  public static int gapY=2;
  
  public static String defaultFontName="Default";
  
  public static int defaultFontSize=12;
  
  public static int defaultFontStyle=Font.PLAIN;
  
  public static Color defaultFgColor=null;
  
  public static Color defaultBgColor=null;
  
  private static Font defaultFont=new Font(defaultFontName,defaultFontSize,
      defaultFontSize);
  
  public static void setColors(Component C) {
    to_default_fg(C);
    to_default_bg(C);
  }
  
  public static void setFonts(Component C) {
    to_default_font(C);
  }
  
  public static void setLooks(Component C) {
    setFonts(C);
    setColors(C);
  }
  
  public GuiBuiltins(){
  }
  
  public static void stopComponent(Component C) {
    if(C instanceof PrologButton) {
      PrologButton B=(PrologButton)C;
      B.stop();
    }
  }
  
  /*
  public static Font getDefaultFont() {
    //Prolog.dump("df="+defaultFont);
    return defaultFont;
  }
  */
  
  public static void set_font_name(String name) {
    if(!name.equals(defaultFontName)) {
      defaultFontName=name;
      defaultFont=new Font(name,defaultFontStyle,defaultFontSize);
    }
  }
  
  public static void set_font_size(int size) {
    defaultFontSize=size;
    defaultFont=new Font(defaultFontName,defaultFontStyle,size);
  }
  
  public static void inc_font_size(int size) {
    size+=defaultFontSize;
    set_font_size(size);
  }
  
  public static void set_font_style(String s) {
    int style=defaultFontStyle;
    if("plain".equals(s))
      style=Font.PLAIN;
    else if("bold".equals(s))
      style=Font.BOLD;
    else if("italic".equals(s))
      style=Font.ITALIC;
    if(defaultFontStyle!=style) {
      defaultFontStyle=style;
      defaultFont=new Font(defaultFontName,style,defaultFontSize);
    }
  }
  
  public static void to_default_font(Component C) {
    C.setFont(defaultFont);
  }
  
  public static void to_default_fg(Component C) {
    if(null==defaultFgColor)
      return;
    C.setForeground(defaultFgColor);
  }
  
  public static void to_default_bg(Component C) {
    if(null==defaultBgColor)
      return;
    C.setBackground(defaultBgColor);
  }
  
  /*
  public static Color get_fg_color() {
    return defaultFgColor;
  }

  public static Color get_bg_color() {
    return defaultBgColor;
  }
  */
  
  public static void set_fg_color(double r,double g,double b) {
    defaultFgColor=new_color(r,g,b);
  }
  
  public static void set_bg_color(double r,double g,double b) {
    defaultBgColor=new_color(r,g,b);
  }
  
  public static LayoutManager to_layout(String name,int x,int y) {
    LayoutManager M=null;
    
    if(name.equals("grid")) {
      M=new GridLayout(x,y,gapX,gapY);
    } else if(name.equals("border")) {
      M=new BorderLayout();
    } else if(name.equals("card")) {
      M=new CardLayout();
    } else if(name.equals("flow")) {
      M=new FlowLayout();
    } else {
      Interact.warnmes("unknown layout: "+name);
      M=new FlowLayout();
    }
    return M;
  }
  
  public static PrologFrame new_frame(String title,String layout,int x,int y,
      int kind) {
    LayoutManager L=GuiBuiltins.to_layout(layout,x,y); // more work to decode
    // grid - etc.
    return new PrologFrame(title,L,kind);
  }
  
  /**
    new_button(PrologContainer,Name,Action,Button): 
    creates a Button with label Name
    and attaches to it an action Action
  */
  public static PrologButton new_button(Container C,String name,
      LogicInteractor M) {
    PrologButton JB=new PrologButton(name,M);
    C.add(JB);
    return JB;
  }
  
  /**
  * new_label(PrologContainer,TextToBeDisplayed,Label): 
  * creates a label with centered text
  *
  */
  
  public static Label new_label(Container C,String name) {
    Label L=new Label(name);
    L.setAlignment(Label.CENTER);
    C.add(L);
    return L;
  }
  
  /*
    set_label: directly through Reflection
  */
  
  public static String new_file_dialog(int mode,String dir) {
    PrologFrame C=new PrologFrame("File Dialog");
    
    FileDialog D;
    if(0==mode) {
      D=new PrologFileDialog(C,"Load",FileDialog.LOAD);
    } else {
      D=new PrologFileDialog(C,"Save",FileDialog.SAVE);
    }
    if(!"?".equals(dir))
      D.setDirectory(dir);
    GuiBuiltins.setLooks(D);
    // D.show();
    D.setVisible(true);
    String fname=D.getFile();
    if(null==fname)
      return null;
    String dname=D.getDirectory();
    if(null==dname)
      return null;
    String result=dname+fname;
    D.dispose();
    C.dispose();
    return result;
  }
  
  public static PrologPanel new_panel(Container C,String layout,int x,int y) {
    LayoutManager L=GuiBuiltins.to_layout(layout,x,y);
    PrologPanel P=new PrologPanel(L);
    C.add(P);
    return P;
  }
  
  /** 
  new_text ARGS:
    1=Parent Container
    2=initial text content
    3=rows
    4=cols
    5=returned handles
  */
  
  public static PrologText new_text(Container C,String oldText,int rows,int cols) {
    PrologText T=new PrologText(oldText);
    if(rows>0&&cols>0) {
      T.setRows(rows);
      T.setColumns(cols);
    }
    C.add(T);
    return T;
  }
  
  /* : in Prolog + Reflection
     get_text(PrologText,Answer):  collects
     the cpntent of thext area to new constant Answer
  */
  
  /*
    in Prolog:
    add_text
    set_text
    get_text
    clear_text
  */
  
  public static Interactor new_gui_io(String prompt,PrologText input,
      PrologText output,Hub hub) {
    return GuiIO.new_interactor(prompt,input,output,hub);
  }
  
  public static Interactor new_gui_o(PrologText output) {
    return GuiO.new_interactor(output);
  }
  
  public static Color new_color(Number r,Number g,Number b) {
    return new_color(r.doubleValue(),g.doubleValue(),b.doubleValue());
  }
  
  public static Color new_color(double r,double g,double b) {
    if(r>1||r<0) {
      Interact.warnmes("new_color arg 1 should be in 0..1->"+r);
    }
    if(g>1||g<0) {
      Interact.warnmes("new_color arg 2 should be in 0..1->"+g);
    }
    if(b>1||b<0) {
      Interact.warnmes("new_color arg 3 should be in 0..1->"+b);
    }
    int R=(int)(r*255.0);
    int G=(int)(g*255.0);
    int B=(int)(b*255.0);
    Color C=new Color(R,G,B);
    return C;
  }
  
  // set_fg,set_bg,set_color : in Prolog
  
  public static void set_direction(Container C,String direction) {
    if(C instanceof PrologFrame)
      ((PrologFrame)C).setDirection(direction);
    else
      ((PrologPanel)C).setDirection(direction);
  }
  
  public static void destroy(Component C) {
    // C.dispose();
    if(C instanceof Container)
      ((Container)C).removeAll();
    C.removeNotify();
  }
  
  public static void set_layout(Container C,String layoutName,int x,int y) {
    // C.removeAll();
    LayoutManager L=to_layout(layoutName,x,y);
    C.setLayout(L);
  }
  
  public static void show(Container C) {
    C.validate();
    C.setVisible(true);
  }
  
  public static void resize(Component C,int h,int v) {
    C.setSize(h,v);
  }
  
  public static void move(Component C,int hpos,int vpos) {
    C.setLocation(hpos,vpos);
  }
  
  /**
    detects if applet and gets applet container
  */
  
  /*public static Applet get_applet() {
    return (Applet)PrologApplet.applet;
  }
  
  public static String get_applet_host() {
    return get_applet().getCodeBase().getHost();
  }
  */
  public static PrologImagePanel new_image(Container C,String src,int width,
      int height) {
    PrologImagePanel P=new PrologImagePanel(src,width,height);
    C.add(P);
    return P;
  }
  
}

class PrologFrame extends Frame {
  
  PrologFrame(String title,LayoutManager L,int kind){
    super(title);
    
    this.kind=kind;
    this.direction=null;
    GuiBuiltins.setLooks(this);
    setSize(GuiBuiltins.defX,GuiBuiltins.defY); // reasonable default size
    
    if(kind>0)
      this.enableEvents(AWTEvent.WINDOW_EVENT_MASK);
    
    if(null!=L)
      setLayout(L); // hgap=10,vgap=10
  }
  
  PrologFrame(String title){
    this(title,null,1);
  }
  
  private int kind;
  
  private String direction;
  
  public void setDirection(String direction) {
    this.direction=direction;
  }
  
  // works only if this.enableEvents has been called
  
  public void processEvent(AWTEvent event) {
    // Interact.println("Frame event:"+event);
    
    if(this.kind>0&&event.getID()==WindowEvent.WINDOW_CLOSING) {
      cleanUp();
    }
    // super.processEvent(event);
  }
  
  private void cleanUp() {
    Component Cs[]=getComponents();
    for(int i=0;i<Cs.length;i++) {
      Component C=Cs[i];
      if(C instanceof PrologButton) {
        PrologButton B=(PrologButton)C;
        B.stop();
      }
    }
    
    dispose();
    // removeNotify();
    removeAll();
  }
  
  public Component add(Component C) {
    if(this.getLayout() instanceof BorderLayout) {
      // Interact.println("adding to: "+direction);
      return super.add(direction,C);
    } else {
      // Interact.println("not adding "+C+" to: "+direction+"<="+this);
      return super.add(C);
    }
  }
}

/*
   Examples of Prolog GUI components - add more !
*/

/**
   Button with attached Prolog action.
   Runs action when Button pushed.
*/
class PrologButton extends Button implements ActionListener {
  PrologButton(String name,LogicInteractor M){
    super(name);
    M.protect_engine();
    this.M=M;
    GuiBuiltins.setLooks(this);
    this.addActionListener(this);
  }
  
  public void actionPerformed(ActionEvent e) {
    // Interact.println("enterActionEvent:"+e+M);
    ask();
    // Interact.println("exitActionEvent:"+e+M);
  }
  
  // private String name;
  // private String action;
  private LogicInteractor M;
  
  private void ask() {
    long answer=0;
    try {
      if(null!=M)
        answer=M.ask();
    } catch(PrologException e) {
      // ok
      // e.printStackTrace();
    } catch(Exception e) {
      // ok - handled in ask
      // e.printStackTrace();
    }
    // $$ Interact.println("!!!M="+M+"=>"+answer);
    if(0==answer) {
      M.unprotect_engine();
      Interact.warnmes("the engine attached to a Prolog Button died");
    }
  }
  
  public void stop() {
    if(null!=M) {
      M.stop();
      M=null;
    }
  }
  
  public void removeNotify() {
    super.removeNotify();
    stop();
  }
}

class PrologPanel extends Panel {
  PrologPanel(LayoutManager L){
    super();
    GuiBuiltins.setLooks(this);
    setLayout(L);
  }
  
  private String direction;
  
  public void setDirection(String direction) {
    this.direction=direction;
  }
  
  public Component add(Component C) {
    if(this.getLayout() instanceof BorderLayout) {
      // Interact.println("adding to: "+direction);
      return super.add(direction,C);
    } else {
      // Interact.println("not adding "+C+" to: "+direction+"<="+this);
      return super.add(C);
    }
  }
  
}

class PrologImagePanel extends Canvas {
  // private String sourceName;
  private Image image;
  
  private int width;
  
  private int height;
  
  PrologImagePanel(String sourceName,int width,int height){
    // this.sourceName=sourceName;
    this.width=width;
    this.height=height;
    GuiBuiltins.setLooks(this);
    /*
    if(null!=PrologApplet.applet) {
      Applet applet=(Applet)PrologApplet.applet;
      URL url=applet.getCodeBase();
      image=applet.getImage(url,sourceName);
    } else
    */
    image=Toolkit.getDefaultToolkit().getImage(sourceName);
  }
  
  // see also (inherited) ImageObserver
  
  public void paint(Graphics g) {
    if(width<=0||height<=0) {
      width=image.getWidth(this);
      height=image.getHeight(this);
    }
    setSize(width,height);
    g.drawImage(image,0,0,width,height,this);
  }
}

/**
 * File filters do not function on Windows - known Java bug
 */
class PrologFileDialog extends FileDialog implements FilenameFilter {
  
  PrologFileDialog(PrologFrame F,String name,int mode){
    super(F,name,mode);
    setFilenameFilter(this);
    GuiBuiltins.setLooks(this);
    
  }
  
  public boolean accept(File dir,String name) {
    // Prolog.dump("accept called with: "+name);
    // return name.endsWith("."+this.filter);
    return true; // this makes behavior uniform accross platforms
  }
}
