## Create a Shortcut with Windows PowerShell
#
## sets the 
$TargetFile = "$env:SystemRoot\System32\cmd.exe"
$ShortcutFile = "$env:Userprofile\Desktop\cmd.lnk"

## Create the shortcut object and place it on the user's desktop
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.WorkingDirectory = "$env:Userprofile\Desktop"
$Shortcut.Save()
