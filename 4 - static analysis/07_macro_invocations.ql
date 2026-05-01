import cpp

from MacroInvocation mi
where mi.getMacroName().regexpMatch("^ntoh.") 
select mi, "ntoh* macro invocation found by regex"