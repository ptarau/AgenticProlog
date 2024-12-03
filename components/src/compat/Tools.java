package compat;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.EOFException;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.util.Arrays;
import java.util.Iterator;
import java.util.Random;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import vm.logic.Fun;
import vm.logic.Interact;
import vm.logic.PrologException;

public class Tools {
  public static String file2string(String url) throws PrologException {
    return reader2string(toReader(url));
  }
  
  public static String reader2string(Reader R) {
    StringBuffer buf=new StringBuffer();
    try {
      int c;
      while((-1)!=(c=R.read())) {
        buf.append((char)c);
      }
    } catch(EOFException e) {
      // ok
    } catch(IOException e) {
      Interact.errmes("error in reader2string",e);
      return null;
    }
    return buf.toString();
  }
  
  public static BufferedReader toReader(InputStream f) {
    return Interact.tryEncoding(f);
  }
  
  public static BufferedReader toReader(String fname) throws PrologException {
    try {
      return Interact.safeFileReader(fname);
    } catch(IOException e) {
      throw new PrologException("file not found: "+fname);
    }
  }
  
  public static BufferedWriter toWriter(String fname,int app)
      throws PrologException {
    boolean append=(1==app)?true:false;
    try {
      return Interact.safeFileWriter(fname,append);
    } catch(IOException e) {
      throw new PrologException("cannot create file: "+fname);
    }
  }
  
  public static void fputc(BufferedWriter f,int c) throws IOException {
    f.append((char)c);
  }
  
  public static final void sort(Object[] a) {
    Arrays.sort(a);
  }
  
  private static final void swap(Object x[],int a,int b) {
    Object t=x[a];
    x[a]=x[b];
    x[b]=t;
  }
  
  public static Random newRandom(int seed) {
    return new Random(12345678901123L^seed);
  }
  
  public static final void shuffle(int seed,Object x[],int max) {
    Random R=newRandom(seed);
    for(int j=max-1;j>1;j--) {
      int i=R.nextInt(j);
      swap(x,i,j);
    }
  }
  
  public static final void shuffle(int seed,Object x[]) {
    shuffle(seed,x,x.length);
  }
  
  /*
  public static final String runCommand(String cmd) throws PrologException {
    try {
      Process P=Runtime.getRuntime().exec(cmd);
      return runProcess(P);
    } catch(Exception e) {
      throw new PrologException("error in OS call: "+e.getMessage()+cmd);
    }
  }
  */
  
  public static final Fun runProcess(Process P,int wait) throws Exception {
    int ret=0;
    if(0==wait)
      return new Fun("",new Integer(0)); // ignore output
    // wait==1 - collect all output
    StringBuffer buf=new StringBuffer();
    
    BufferedReader in=toReader(P.getInputStream());
    
    // BufferedReader err=toReader(P.getErrorStream());
    String s;
    while((s=in.readLine())!=null) {
      buf.append(s+Interact.NL);
    }
    
    in.close();
    if(wait>1) // wait for termination
    {
      OutputStreamWriter out=new OutputStreamWriter(P.getOutputStream());
      out.write("\n");
      out.close();
      ret=P.waitFor();
      // if(ret>0)
      // Interact.warnmes("!!! warning: process returned="+ret);
    }
    return new Fun("x",buf.toString(),new Integer(ret));
  }
  
  public static void killProcess(Process P) {
    try {
      P.destroy();
    } catch(Exception e) {
    }
  }
  
  public static InputStream zip2stream(String jarname,String fname,boolean quiet) {
    try {
      File JF=new File(jarname);
      if(!JF.exists())
        return null;
      ZipFile jf=new ZipFile(JF);
      ZipEntry entry=jf.getEntry(fname);
      if(null==entry)
        return null;
      return jf.getInputStream(entry);
    } catch(Throwable e) {
      if(!quiet)
        Interact.warnmes("error opening zip or jar file component: "+jarname
            +":"+fname);
      return null;
    }
  }
  
  public static int jar2file(String JarName,String FileNameInJar,
      String NewFileName) throws IOException,PrologException {
    InputStream is=zip2stream(JarName,FileNameInJar,false); // change to true if
    if(null==is) {
      throw new PrologException("not found in "+JarName+" file="+FileNameInJar);
    }
    FileOutputStream os=new FileOutputStream(NewFileName,false);
    int c=0;
    while((c=is.read())!=-1) {
      os.write(c);
    }
    is.close();
    os.close();
    return 1;
  }
  
  public static Iterator props() {
    return System.getProperties().keySet().iterator();
  }
}
