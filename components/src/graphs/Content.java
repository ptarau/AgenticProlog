package graphs;

import vm.logic.Stateful;

public final class Content implements Stateful {
  Object key;
  
  Object value;
  
  final Object data;
  
  public Content(Object key,Object value,Object data){
    this.key=key;
    this.value=value;
    this.data=data;
  }
  
  public String toString() {
    return "("+key+","+value+","+data+")";
  }
}
