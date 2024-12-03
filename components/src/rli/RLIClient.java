package rli;

import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

import vm.logic.Interact;

public class RLIClient {
  
  public static Object rli_in(String host,String portName) {
    try {
      Registry registry=LocateRegistry.getRegistry(host);
      ServerStub stub=(ServerStub)registry.lookup(portName);
      Object answer=stub.rli_in();
      return answer;
    } catch(Exception e) {
      Interact.warnmes("Error in rli_in: "+e.getClass()+",port="+portName);
      if(RLIAdaptor.trace)
        e.printStackTrace();
      return null;
    }
  }
  
  public static void rli_out(String host,String portName,Object T) {
    try {
      Registry registry=LocateRegistry.getRegistry(host);
      ServerStub stub=(ServerStub)registry.lookup(portName);
      stub.rli_out(T);
    } catch(Exception e) {
      Interact.warnmes("Error in rli_out: "+e.getClass()+",port="+portName
          +",term="+T);
      if(RLIAdaptor.trace)
        e.printStackTrace();
    }
  }
  
  /*
  public static void stopServer(String host,String portName) {
    rli_out(host,portName,null);
  }
  */

  public static int rli_stop_server(String host,String portName) {
    try {
      Registry registry=LocateRegistry.getRegistry(host);
      ServerStub stub=(ServerStub)registry.lookup(portName);
      return stub.rli_stop_server();
    } catch(Exception e) {
      return 0;
    }
  }
  
  public static int rli_ping(String host,String portName) {
    try {
      Registry registry=LocateRegistry.getRegistry(host);
      ServerStub stub=(ServerStub)registry.lookup(portName);
      return stub.rli_ping();
    } catch(Exception e) {
      return 0;
    }
  }
  
  public static Object rli_call(String host,String portName,Object T) {
    try {
      Registry registry=LocateRegistry.getRegistry(host);
      ServerStub stub=(ServerStub)registry.lookup(portName);
      return stub.rli_call(T);
    } catch(Exception e) {
      Interact.warnmes("Error in rli_out: "+e.getClass()+",port="+portName
          +",term="+T);
      if(RLIAdaptor.trace)
        e.printStackTrace();
      return null;
    }
  }
  
}
