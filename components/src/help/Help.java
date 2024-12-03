package help;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.EOFException;
import java.io.File;
import java.io.IOException;
import java.net.NetworkInterface;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.Iterator;

import vm.logic.Interact;
import vm.logic.ObjectStack;

/**
 * Prolog helper
 */
public class Help {
  public static void main(String[] args) {
    make_help();
  }
  
  public static Iterator search_help(String keyword,String[] helps) {
    ArrayList A=new ArrayList();
    for(int i=0;i<helps.length;i++) {
      String helpLine=helps[i];
      if(helpLine.contains(keyword))
        A.add(helpLine);
    }
    return A.iterator();
  }
  
  static String header="package help;\n"+"\npublic class HelpData {\n"
      +"  public final static String[] getData() {\n    return helps;\n  }\n\n"
      +"  private final static String[] helps=new String[] {\n\n";
      
  static String footer="\n    \"make_help: generates help file -- help.pl\"};\n}\n";
  
  static String doctitle="Lean Prolog Predicate Reference Guide";
  
  static String docheader="<html><head><title>"+doctitle
      +"</title></head>\n<body>\n<H1>"+doctitle+"</H1>\n\n";
      
  static String docfooter="\n</body>\n</html>\n";
  
  public static void make_help() {
    String[] dirs=new String[] { "../prologL/psrc", "../prologL/compiler",
        "./src/agents", "./src/graphs", "./src/compat", "./src/gui",
        "./src/styla", "./src/net",
        "../../vivoExtensions/components/src/vivoLibs" };
    try {
      make_help(dirs);
    } catch(Exception e) {
      e.printStackTrace();
    }
  }
  
  public static void make_help(String[] dirs) {
    String suf=".pl";
    
    try {
      String hf="src/help/HelpData.java";
      String docf="src/help/HelpData.html";
      
      ArrayList W=new ArrayList();
      ArrayList DOCW=new ArrayList();
      
      for(int k=0;k<dirs.length;k++) {
        String dir=dirs[k];
        File d=new File(dir);
        if(!d.exists()||!d.isDirectory()) {
          Interact.println("*** skiping bad directory in collectHelp: "+dir);
          continue;
        }
        Interact.println(">>> collecting %% help from files in: "+dir);
        File[] fs=d.listFiles();
        
        for(int i=0;i<fs.length;i++) {
          String fname=fs[i].toString();
          if(!fname.endsWith(suf))
            continue;
            
          BufferedReader r=Interact.safeFileReader(fname);
          int slash=fname.lastIndexOf('/');
          if(slash>0)
            fname=fname.substring(slash+1);
          Interact.println("  >>> collecting from: "+fname);
          try {
            
            for(;;) {
              String l=r.readLine();
              if(null==l)
                break;
              l=l.trim();
              if(l.startsWith("%%")) {
                l=l.substring(2).trim();
                
                l=l+" -- "+fname;
                l=l.replace("\\","\\\\");
                l=l.replace('\"','\'');
                
                // l="helpData(\""+l+"\").";
                l="    \""+l+"\",";
                
                W.add(l+"\n");
                
                l=l.replace("\\\\","\\");
                int iSep=l.indexOf(':');
                if(iSep>0) {
                  String hd=l.substring(0,iSep);
                  String tl=l.substring(iSep+1);
                  
                  DOCW.add("<b>"+hd+":</b> "+tl+"<p>\n");
                  
                }
              }
            }
          } catch(EOFException eof) {
          }
          r.close();
        }
        
      }
      
      BufferedWriter w=Interact.safeFileWriter(hf);
      BufferedWriter docw=Interact.safeFileWriter(docf);
      w.write(header);
      docw.write(docheader);
      
      Object[] ws=W.toArray();
      Arrays.sort(ws);
      for(int i=0;i<ws.length;i++) {
        w.write((String)ws[i]);
      }
      
      Object[] ds=DOCW.toArray();
      Arrays.sort(ds);
      for(int i=0;i<ds.length;i++) {
        docw.write((String)ds[i]);
      }
      
      w.write(footer);
      docw.write(docfooter);
      w.close();
      docw.close();
    } catch(IOException e) {
      Interact.warnmes("error in collectHelp: "+e);
    }
  }
  
  public static Object get_hardware_id() {
    ObjectStack s=new ObjectStack();
    try {
      Enumeration e=NetworkInterface.getNetworkInterfaces();
      while(e.hasMoreElements()) {
        NetworkInterface I=(NetworkInterface)e.nextElement();
        byte[] ha=I.getHardwareAddress();
        if(null!=ha) {
          for(int i=0;i<ha.length;i++) {
            int b=ha[i];
            if(b<0)
              b=256-b;
            b='a'+b%26;
            s.push(new Integer(b));
            
          }
        }
      }
    } catch(Exception x) {
      x.printStackTrace();
    }
    return s.toList();
  }
}
