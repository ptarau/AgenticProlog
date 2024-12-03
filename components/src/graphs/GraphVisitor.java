package graphs;

import vm.logic.Stateful;

public interface GraphVisitor extends Stateful {
  public void init();
  
  public void start();
  
  public void stop();
  
  public Object end();
  
  public boolean isVisited(Object V);
  
  public boolean visitIn();
  
  public boolean visitOut();
  
  public void visit(Object V);
  
  public void unvisit(Object V);
}
