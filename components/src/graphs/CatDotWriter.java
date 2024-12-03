package graphs;

// writes to graphviz file

// rancat(C),to_dot(C,'boo.gv')

import java.io.BufferedWriter;
import java.io.IOException;

import vm.logic.Interact;

public class CatDotWriter implements CatWalker {
  CatDotWriter(BufferedWriter writer,int verboseVs,int verboseEs){
    this.writer=writer;
    this.verboseVs=verboseVs;
    this.verboseEs=verboseEs;
  }
  
  CatDotWriter(String fileName,int verboseVs,int verboseEs) throws IOException{
    this(Interact.safeFileWriter(fileName),verboseVs,verboseEs);
  }
  
  // private PrologWriter writer;
  private BufferedWriter writer;
  
  private int verboseVs,verboseEs;
  
  private void pp(Object s) {
    try {
      writer.append(s.toString());
      writer.newLine();
    } catch(IOException e) {
    }
  }
  
  public static String js(Object s) {
    // return xjs(Interact.forceEncodingOf(s.toString(),"MacRoman","UTF-8"));
    return xjs(s.toString());
  }
  
  /**
   * cleans up string such that it is usable, when generating Java
   * as a syntactically ok String - e.g. it escapes " as \" 
   */
  private static String xjs(String s) {
    StringBuffer buf=new StringBuffer();
    for(int i=0;i<s.length();i++) {
      char c=s.charAt(i);
      if(c=='\n'||c=='\r'||c=='|') {
        buf.append(' ');
        /*  
        } else if(c<32||c>127) {
          buf.append(" \\"+(int)c+" ");
        */
      } else if('\"'==c) {
        buf.append('\'');
      } else
        buf.append(c);
    }
    return buf.toString();
  }
  
  public void atStart() {
    pp("digraph {\n"+"\tmargin = \"0\"\n"+"\tpage = \"0.0,0.0\"\n"
        +"\tsize = \"0.0,0.0\"\n"+"\trotate = \"0\"\n"+"\tratio = \"fill\"");
    
  }
  
  public void beforeProps() {
    pp("#vertices");
  }
  
  public void onProp(Object vertex,Object key,Object value) {
    Object lvertex=vertex;
    String key_val=""; // 0 is default
    if(this.verboseVs==1)
      key_val=":"+value;
    else if(this.verboseVs==2)
      key_val=":"+key+"="+value;
    else if(this.verboseVs==3) {
      lvertex=key;
    }
    pp("\t"+js(vertex)+" [label = \""+js(lvertex)+js(key_val)+"\"]");
  }
  
  public void afterProps() {
  }
  
  public void beforeMorphisms() {
    pp("#edges");
  }
  
  public void onMorphism(Object from,Object to,Object m,Object md) {
    String key_val=""; // 0 is default
    if(this.verboseEs==1)
      key_val=md.toString();
    else if(this.verboseEs==2)
      key_val=m+"=>"+md;
    
    pp("\t "+js(from)+" -> "+js(to)+" [label = \""+js(key_val)+"\"]");
  }
  
  public void afterMorphisms() {
  }
  
  public Object atEnd() {
    pp("}");
    try {
      writer.close();
    } catch(IOException e) {
    }
    return null;
  }
}
