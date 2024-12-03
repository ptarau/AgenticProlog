package styla;

import java.util.LinkedHashMap;

import prolog.LogicEngine;
import prolog.terms.Term;
import vm.logic.Fun;
import vm.logic.Var;

public class Inter {
  public static void pp(Object o) {
    System.out.println(o);
  }
  
  public static prolog.LogicEngine new_styla_engine() {
    return new prolog.LogicEngine();
  }
  
  public static int stop_styla_engine(prolog.LogicEngine E) {
    E.stop();
    return 1;
  }
  
  public static int styla_engine_set_goal(prolog.LogicEngine E,Object A,
      Object G) {
    prolog.terms.Term[] ag=toStylaPair(A,G);
    E.setGoal(ag[0],ag[1]);
    return 1;
  }
  
  public static int styla_engine_set_goal_string(prolog.LogicEngine E,
      Object G) {
    // pp("g="+G);
    E.setGoal((String)G);
    return 1;
  }
  
  public static Object ask_styla_engine(prolog.LogicEngine E) {
    prolog.terms.Term a=E.askAnswer();
    Object A=fromStyla(a);
    return A;
  }
  
  /**
   * converts Java Fun/Var term to Styla Prolog term
   * @param t
   */
  public static Term toStyla(Object t) {
    LinkedHashMap vars=new LinkedHashMap();
    Term res=toStyla(t,vars);
    // pp("toStyla vars:"+vars);
    return res;
    
  }
  
  public static Term[] toStylaPair(Object v,Object t) {
    LinkedHashMap vars=new LinkedHashMap();
    Term V=toStyla(v,vars);
    Term T=toStyla(t,vars);
    // pp("toStyla vars:"+vars);
    Term[] res=new Term[2];
    res[0]=V;
    res[1]=T;
    return res;
    
  }
  
  private static prolog.terms.Term toStyla(Object t,LinkedHashMap vars) {
    Term res=null;
    if(t instanceof Var) {
      prolog.terms.Var v=(prolog.terms.Var)vars.get(t);
      if(null==v) {
        prolog.terms.Var sv=new prolog.terms.Var();
        vars.put(t,sv);
        res=sv;
      } else
        res=v;
    } else if(t instanceof Fun) {
      Fun f=(Fun)t;
      String name=f.name.toString();
      int l=f.args.length;
      if(0==l) {
        res=LogicEngine.newConst(name);
      } else {
        prolog.terms.Term[] args=new prolog.terms.Term[l];
        // prolog.terms.Fun sf=new prolog.terms.Fun(name,args);
        for(int i=0;i<l;i++) {
          args[i]=toStyla(f.args[i],vars);
        }
        prolog.terms.Fun sf=LogicEngine.newFun(name,args);
        res=sf;
      }
    } else if(t instanceof String) {
      res=LogicEngine.newConst((String)t);
    } else if(t instanceof Integer) {
      res=new prolog.terms.SmallInt((Integer)t);
    } else if(t instanceof java.math.BigDecimal) {
      scala.math.BigDecimal st=new scala.math.BigDecimal(
          (java.math.BigDecimal)t);
      res=new prolog.terms.Real(st);
    } else {
      pp("unexpected Java term in toStyla !!!"+t+t.getClass());
      res=LogicEngine.newConst("?"+t+"?");
    }
    return res;
  }
  
  /**
   * Converts Styla Prolog term to Java Fun/Var term
   * also numbers are converted (see all as BigDecimals)
   * non-numeric objects other then Var or Fun are kept unchanged when
   * listed as arguments of a Fun
   * @param t
   */
  public static Object fromStyla(Term t) {
    LinkedHashMap vars=new LinkedHashMap();
    Object res=fromStyla(t,vars);
    // pp("--");pp(vars);pp("--");
    return res;
  }
  
  private static Object fromStyla(Term t0,LinkedHashMap vars) {
    Object res=null;
    Term t=(t0 instanceof prolog.terms.Var)?t0.ref():t0;
    if(t instanceof prolog.terms.Var) {
      prolog.terms.Var v=(prolog.terms.Var)t;
      // pp("var="+t);
      Object O=vars.get(v);
      int i;
      if(null==O) {
        i=vars.size();
        Integer I=new Integer(i);
        vars.put(v,I);
      } else
        i=((Integer)O).intValue();
      res=new Var(i);
    } else if(t instanceof prolog.terms.Fun) {
      prolog.terms.Fun f=(prolog.terms.Fun)t;
      int l=f.len();
      Object[] jargs=new Object[l];
      Fun jf=new Fun(f.getName(),jargs);
      for(int i=0;i<l;i++) {
        jargs[i]=fromStyla(f.getArg(i),vars);
      }
      res=jf;
    } else if(t instanceof prolog.terms.Const) {
      prolog.terms.Const c=(prolog.terms.Const)t;
      res=c.getName();
      
    } else if(t instanceof prolog.terms.SmallInt) {
      prolog.terms.SmallInt s=(prolog.terms.SmallInt)t;
      
      Integer j=s.nval();
      res=j;
    }
    
    else if(t instanceof prolog.terms.Num)
    
    {
      prolog.terms.Num c=(prolog.terms.Num)t;
      scala.math.BigDecimal snum=(scala.math.BigDecimal)c.getValue();
      java.math.BigDecimal jnum=snum.bigDecimal();
      res=jnum;
    } else
    
    {
      // pp("$$$"+t+t.getClass());
      res=t;
    }
    
    return res;
    
  }
  
  public static void main(String[] args) {
    /*
    // a static variant - if you know you only need one engine
    public static defaultLogicEngine=null
    public static void initProlog() = {
      defaultLogicEngine=new LogicEngine();
    }
    */
    
    LogicEngine logicEngine=new LogicEngine();
    
    /* logicEngine.setGoal("consult('simple')");
       logicEngine.askAnswer();
    
       logicEngine.setGoal("b(X)");
    
    boolean more=true;
    while(more) {
      Object answer=logicEngine.askAnswer();
      if(null==answer)
        more=false;
      else
        pp("answer="+answer);
    }
    */
    
    logicEngine.setGoal("nonvar(f(X,h(a,b,42),g(Y,X,Z,3.14,Y)))");
    Term sterm1=(Term)logicEngine.askAnswer();
    pp("sterm1="+sterm1);
    Object jterm1=fromStyla(sterm1);
    System.out.println("jterm1="+jterm1);
    Term sterm2=toStyla(jterm1);
    System.out.println("sterm2="+sterm2);
    Object jterm2=fromStyla(sterm2);
    System.out.println("jterm2="+jterm2);
    logicEngine.stop();
    // logicEngine.setGoal("halt");
    // logicEngine.askAnswer();
    
  }
}
