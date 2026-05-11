Set sh = CreateObject("WScript.Shell")
sh.Run "powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\screenshots\screencap.ps1", 0, True
