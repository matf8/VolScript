Option Explicit

Dim fso, installPath, processName, scriptPath, cmd

If WScript.Arguments.Count < 1 Then
    WScript.Quit 1
End If

processName = WScript.Arguments(0)

Set fso = CreateObject("Scripting.FileSystemObject")
installPath = fso.GetParentFolderName(fso.GetParentFolderName(WScript.ScriptFullName))
scriptPath = installPath & "\VolScript.ps1"

If Not fso.FileExists(scriptPath) Then
    WScript.Quit 1
End If

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """ " & processName & " -q"

CreateObject("Wscript.Shell").Run cmd, 0, False
