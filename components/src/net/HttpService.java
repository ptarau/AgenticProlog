package net;

import java.io.BufferedInputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.util.StringTokenizer;

import vm.extensions.Transport;
import vm.logic.Fun;
import vm.logic.IntStack;
import vm.logic.Interact;
import vm.logic.LogicEngine;
import vm.logic.LogicInteractor;
import vm.logic.Prolog;
import vm.logic.PrologException;
import vm.logic.Stateful;
import vm.logic.Var;

import compat.Tools;

/**
 * Implements basic HTTP protocol allowing Prolog to act like a
 * a self contained Web service - in particular to serve it's
 * own code and Prolog files over the Web for supporting a Prolog applet.
 * 
 * use: 
 *  run_http_server -- on default Port 8001
 *  run_http_server(Port)    
 */
public class HttpService implements Runnable,Stateful {
  transient private Socket serviceSocket;
  
  private String www_root;
  
  private Prolog prolog;
  
  public HttpService(Socket serviceSocket,String www_root,LogicEngine E){
    this.serviceSocket=serviceSocket;
    this.www_root=www_root;
    this.prolog=E.prolog;
  }
  
  byte[] fileORjarfile2bytes(String fname) throws IOException {
    // Prolog.dump("trying: "+fname);
    try {
      return Transport.file2bytes(fname);
    } catch(IOException e) {
      // throw e;
      if(fname.startsWith("./"))
        fname=fname.substring(2);
      InputStream in=Tools.zip2stream(Interact.PROLOG_JAR_FILE,fname,true);
      if(null==in)
        throw e;
      BufferedInputStream stream=new BufferedInputStream(in);
      // Prolog.dump("zipstore: "+fname);
      try {
        return streamToBytes(stream);
      } catch(PrologException ee) {
        throw e;
      }
    }
  }
  
  public static byte[] streamToBytes(InputStream in) throws PrologException {
    if(null==in)
      return null;
    try {
      IntStack is=new IntStack();
      for(;;) {
        int c=in.read();
        if(c==-1)
          break;
        is.push((byte)c);
      }
      in.close();
      return is.toByteArray();
    } catch(IOException e) {
      throw new PrologException("error in zip file");
    }
  }
  
  public static String content_header="HTTP/1.0 200 OK\nContent-Length: ";
  
  private final String fix_file_name(String f) {
    return www_root.concat((f.endsWith("/")?f.concat("index.html"):f));
  }
  
  static private final String nextToken(String s) {
    StringTokenizer t=new StringTokenizer(s," ");
    t.nextToken();
    return t.nextToken();
  }
  
  public void run() {
    try {
      DataInputStream in=new DataInputStream(serviceSocket.getInputStream());
      DataOutputStream out=new DataOutputStream(serviceSocket.getOutputStream());
      try {
        while(true) {
          String s=in.readLine();
          if(s.length()<1)
            break;
          if(s.startsWith("GET")) {
            // Prolog.dump(s);
            String f=nextToken(s);
            f=fix_file_name(f);
            byte[] bs=fileORjarfile2bytes(f);
            // Interact.println("cl="+bs.length);
            out.writeBytes(content_header+bs.length+"\n\n");
            Transport.bwrite_to(out,bs);
          }
          if(s.startsWith("POST")) {
            // Interact.dump("@@@>"+s);
            String f=nextToken(s);
            f=fix_file_name(f);
            String line="?";
            String contentLength=null;
            // String userAgent=null;
            int max=100;
            while(--max>0&&(!line.equals(""))) {
              line=in.readLine().toLowerCase();
              if(line.startsWith("content-length:"))
                contentLength=nextToken(line);
              else if(line.startsWith("user-agent:"))
                // userAgent=
                nextToken(line);
            }
            
            int content_length=Integer.parseInt(contentLength);
            // Interact.println("@@@ cl="+content_length);
            
            byte[] is=new byte[content_length];
            in.readFully(is);
            
            // Interact.println("@@@ READ!!!=");
            String query=new String(is,Interact.getEncoding());
            
            // Interact.println("### call_prolog_post_handler QUERY=>"+query);
            String result=call_prolog_post_handler(query,f);
            // Interact.println("### call_prolog_post_handler RESULT=>"+result);
            
            byte[] os;
            if(null==result||result==f) {
              // use template file
              os=fileORjarfile2bytes(f);
            } else {
              // use result - it assumes the client
              // processed the template file + action script
              os=result.getBytes(Interact.getEncoding());
            }
            out.writeBytes(content_header+os.length+"\n\n");
            Transport.bwrite_to(out,os);
          } else /* ignore other headers */
          {
            // Prolog.dump(s);
          }
          
        }
      } catch(Exception e) {
        out.writeBytes("HTTP/1.0 404 ERROR\n\n\n");
      }
      in.close();
      out.close();
    } catch(SocketException se) {
      // ok- just trying to write - when client closed first
    } catch(Exception ee) {
      Interact.errmes("http_service_error",ee);
    }
  }
  
  private final String call_prolog_post_handler(String is,String os) {
    // Machine M=Top.new_machine(null,null);
    // Interact.println("ENTERING call_prolog_post_handler");
    try {
      LogicInteractor M=LogicInteractor.new_interactor(Prolog.CLONE,prolog);
      // Interact.println(prolog.enginfo());
      // Interact.println("ENGINE in call_prolog_post_handler: "+M);
      if(null==M) {
        Interact.warnmes("null M in POST method handler");
        return null;
      }
      Object R=new Var(1);
      // Interact.println("@@@ HERE");
      Fun Goal=new Fun("post_method_wrapper",is,os,R);
      Fun Query=new Fun(":-",R,Goal);
      if(!M.load_engine(Query))
        return null;
      
      // to allow gc of objects involved. the Prolog query should not fail !!!
      Object answer=M.ask_interactor();
      // M.removeObject(is);
      // M.removeObject(os);
      // M.removeObject(answer);
      M.stop();
      // Interact.println(prolog.enginfo());
      if("no".equals(answer))
        return null;
      if(answer instanceof Fun)
        answer=((Fun)answer).args[0];
      return answer.toString();
    } catch(Exception e) {
      Interact.warnmes("exception in POST method handler",e);
      return null;
    }
  }
  
  /**
   * Starts a HTTP server rooted in the directory www_root
   */
  public static void run_http_server(int port,String www_root,LogicEngine E) {
    try {
      ServerSocket serverSocket=new ServerSocket(port);
      while(true) {
        Socket serviceSocket=serverSocket.accept();
        HttpService service=new HttpService(serviceSocket,www_root,E);
        service.run();
      }
    } catch(Exception e) {
      Interact.errmes("http_server_error",e);
    }
  }
}
