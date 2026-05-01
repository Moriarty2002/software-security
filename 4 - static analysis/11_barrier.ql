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
    exists(GuardCondition gc, Variable var |
      
      // Checks that the node is an access to a variable, 
      // and that the same variable is also accessed somewhere 
      // inside the guard condition
      node.asExpr() = var.getAnAccess() and
      gc.(Expr).getAChild*() = var.getAnAccess()
      and
      (
        // CASE 1: Early Exit (use return)
        // The guard controls a block that forces a return
        // before the source reach the sink
        exists(ReturnStmt ret |
          gc.controls(ret.getBasicBlock(), _) and
          gc.controls(node.asExpr().getBasicBlock(), _)
        )
        
        or 
        
        // CASE 2: Reassignment
        // The variable is reassigned under the guard condition
        // eg [if (x > 2) then x = 2]
        // and does not reassign using itself (rejects `x = x + 1`)
        exists(AssignExpr assign |
          assign.getLValue() = var.getAnAccess() and
          gc.controls(assign.getBasicBlock(), _) and
          assign.getBasicBlock().getASuccessor*() = node.asExpr().getBasicBlock() and
          // self reassignment are not safe
          not assign.getRValue().getAChild*() = var.getAnAccess()
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