package rli;

import vm.logic.Interact;

public class RLIAdaptor {
  
  public static boolean trace=false;
  
  /**
   * Independent testing function
   */
  public static void main(String args[]) {
    String host=null; // means "localhost";
    String portName="7777"; // ll ports are virtual - their names are strings -
    // avoid confusion with socket layers
    if("server".equals(args[0])) {
      if(rli_start_server(portName)<0)
        System.exit(1);
    } else {
      // Fun goal=new Fun("println","hello");
      String goal="hello";
      rli_out(host,portName,goal);
      Object answer=rli_in(host,portName);
      System.out.println("got: "+answer);
    }
  }
  
  // basic named port API
  
  //
  public static int rli_start_server(String portName) {
    RLIServer server=new RLIServer(portName);
    int r=server.start(); // first !!!
    return r;
  }
  
  public static void rli_stop_server(String host,String portName) {
    RLIClient.rli_stop_server(host,portName);
  }
  
  public static Object rli_in(String host,String port) {
    return RLIClient.rli_in(host,port);
  }
  
  public static void rli_out(String host,String port,Object T) {
    RLIClient.rli_out(host,port,T);
  }
  
  public static Object rli_call(String host,String port,Object T) {
    Object R=RLIClient.rli_call(host,port,T);
    if(null==R) {
      Interact.warnmes("got null answer from "+host+":"+port);
      return "no";
    }
    return R;
  }
  
  public static int rli_ping(String host,String port) {
    return RLIClient.rli_ping(host,port);
  }
  
  // derived int port API - for backward compatilility
  
  public static int rli_start_server(int port) {
    return rli_start_server(""+port);
  }
  
  public static void rli_stop_server(String host,int port) {
    rli_stop_server(host,""+port);
  }
  
  public static int rli_ping(String host,int port) {
    return rli_ping(host,""+port);
  }
  
  /*
  public static Fun rli_get_inets() {
    Vector V=new Vector();
    try {
      Enumeration E=NetworkInterface.getNetworkInterfaces();
      while(E.hasMoreElements()) {
        NetworkInterface I=(NetworkInterface)E.nextElement();
        Enumeration A=I.getInetAddresses();
        while(A.hasMoreElements()) {
          InetAddress IA=(InetAddress)A.nextElement();
          if(IA.isSiteLocalAddress()) {// || IA.isLoopbackAddress()) {
            String adr=IA.getHostAddress();
            // String adr=IA.getCanonicalHostName();
            // String adr=IA.toString();
            V.addElement(adr);
          }
        }
      }
      // System.err.println("!!!V="+V);
      Object[] args=V.toArray();
      return new Fun("inetAddresses",args);
    } catch(Exception e) {
      e.printStackTrace();
      return null;
    }
  }
  */
}
