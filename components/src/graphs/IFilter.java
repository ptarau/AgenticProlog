package graphs;

import vm.logic.Stateful;

public interface IFilter extends Stateful {
  public Object filterVertex(Object VData);
  
  public Object filterEdge(Object EData);
}
