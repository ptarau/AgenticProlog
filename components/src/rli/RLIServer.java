package rli;

import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.rmi.server.UnicastRemoteObject;

import vm.extensions.Hub;
import vm.logic.LogicInteractor;

public class RLIServer implements ServerStub {
  
  private String portName;
  
  private Hub hub;
  
  public RLIServer(String portName){
    this.portName=portName;
  }
  
  public String getPort() {
    return portName;
  }
  
  /**
   * equivalent to rmiregistry.exe creates a registry if not already created
   */
  public void create_registry() {
    try {
      // System.setProperty("java.rmi.server.codebase","file:/bin/lprolog.jar");
      java.rmi.registry.LocateRegistry.createRegistry(Registry.REGISTRY_PORT);
    } catch(RemoteException re) {
      // System.err.println("Registry Creation exception: "+ re.toString());
    } catch(Exception e) {
      System.err.println("Registry Creation error: "+e.toString());
    }
  }
  
  public int start() {
    create_registry();
    try { // ?? maybe the stub needs to be returned?
      ServerStub stub=(ServerStub)UnicastRemoteObject.exportObject(
          this,0);
      
      // (Re)Bind the remote object's stub in the registry
      Registry registry=LocateRegistry.getRegistry();
      registry.rebind(this.portName,stub);
      
      // System.err.println("Starting Server: " + this.portName);
    } catch(Exception e) {
      System.err.println("Server start exception: "+e.toString()+",port="
          +portName);
      if(RLIAdaptor.trace)
        e.printStackTrace();
      System.err.println("Please make sure you have started rmiregistry");
      return 0;
    }
    if(null==hub)
      hub=new Hub();
    return 1;
  }
  
  public Object rli_in() {
    return hub.ask_interactor();
  }
  
  public void rli_out(Object T) {
    if(null!=T) {
      hub.tell_interactor(T);
      return;
    }
    // hub.tell_interactor("stopping");
    rli_stop_server();
  }
  
  public int rli_stop_server() {
    System.err.println("Stopping Server: "+this.portName);
    int ok;
    try {
      // Thread.sleep(2000); // makes sure message is sent out
      Registry registry=LocateRegistry.getRegistry();
      registry.unbind(this.portName);
      ok=UnicastRemoteObject.unexportObject(this,true)?1:0;
    } catch(Exception e) {
      System.err.println("Server stop exception: "+e.toString());
      e.printStackTrace();
      ok=0;
    }
    hub.stop_interactor();
    return ok;
  }
  
  public int rli_ping() {
    if(busy)
      return 0;
    return 1;
  }
  
  LogicInteractor machine=LogicInteractor.new_interactor();
  
  boolean busy=false;
  
  public Object rli_call(Object query) {
    Object R=null;
    
    if(null==query) { // this stops server
      rli_stop_server();
      machine.dismantle();
      return null;
    }
    
    // if machine is reused, new tasks will stop previous tasks - unexpected
    // behavior !!!
    
    if(busy)
      return null;
    
    busy=true;
    
    R=LogicInteractor.call_engine(machine,query); // does work on server
    if("no".equals(R)) {
      // Interact.dump("here: "+query);
      machine.dismantle();
      machine=LogicInteractor.new_interactor();
    }
    busy=false;
    
    return R;
  }
}
