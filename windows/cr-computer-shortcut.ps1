$TargetFile = "$env:SystemRoot\explorer.exe"
$ShortcutFile = "$env:Userprofile\Desktop\Computer.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = "\/e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
$Shortcut.Save()
