package rli;

import java.rmi.Remote;
import java.rmi.RemoteException;

public interface ServerStub extends Remote {
  public Object rli_in() throws RemoteException;
  
  public void rli_out(Object T) throws RemoteException;
  
  public int rli_ping() throws RemoteException;
  
  public int rli_stop_server() throws RemoteException;
  
  public Object rli_call(Object T) throws RemoteException;
}
