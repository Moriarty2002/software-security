/**
 * @kind path-problem
 */

 import cpp
 import semmle.code.cpp.dataflow.TaintTracking
 import semmle.code.cpp.controlflow.Guards
 
 class NetworkByteSwap extends Expr {
    NetworkByteSwap () {
      exists(MacroInvocation mi |
        mi.getMacroName().regexpMatch("^ntoh(l|s|ll)$") and
        this = mi.getExpr()
      )
    }
  }
 
 module MyConfig implements DataFlow::ConfigSig {
 
   predicate isSource(DataFlow::Node source) {
     source.asExpr() instanceof NetworkByteSwap
   }
   predicate isSink(DataFlow::Node sink) {
      exists(FunctionCall fc |
      fc.getTarget().getName() = "memcpy" and
      sink.asExpr() = fc.getArgument(2)
    )
   }
  
  predicate isBarrier(DataFlow::Node node) {
    exists(
      Variable v,
      RelationalOperation cmp,
      IfStmt ifs
    |
      // tainted value corresponds to variable access
      node.asExpr() = v.getAnAccess() and
  
      // variable appears somewhere in the comparison expression
      cmp.getAChild*() = v.getAnAccess() and
      ifs.getCondition() = cmp and
  
      (
        // Case 1: invalid path exits
        exists(ReturnStmt ret |
          ret = ifs.getThen().getAChild*()
        )
  
        or
  
        // Case 2: value is reassigned before sink
        exists(AssignExpr assign |
          assign.getLValue() = v.getAnAccess() and
          assign = ifs.getThen().getAChild*() and
          assign.getBasicBlock().getASuccessor*() =
            node.asExpr().getBasicBlock() and
          not assign.getRValue().getAChild*() = v.getAnAccess()
        )
      )
    )
  }
  
 }
 
 module MyTaint = TaintTracking::Global<MyConfig>;
 import MyTaint::PathGraph
 
 from MyTaint::PathNode source, MyTaint::PathNode sink
 where MyTaint::flowPath(source, sink) 
 select sink, source, sink, "Network byte swap flows to memcpy"