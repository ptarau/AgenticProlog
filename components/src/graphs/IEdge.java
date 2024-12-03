package graphs;

import vm.logic.Stateful;

public final class IEdge implements Stateful {
  public final int to;
  
  public Object data;
  
  public IEdge(int to,Object data){
    this.to=to;
    this.data=data;
  }
  
  public String toString() {
    return (null==data)?null:data.toString();
  }
}
