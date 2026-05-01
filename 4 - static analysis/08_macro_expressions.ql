import cpp

from MacroInvocation mi
where mi.getMacroName().regexpMatch("^ntoh.") 
select mi.getExpr(), "ntoh* macro top level expression found by regex"