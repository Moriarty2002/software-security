import cpp

from Macro m
where m.getName().regexpMatch("^ntoh.")
select m, "ntoh* macro found by compact regex condition"