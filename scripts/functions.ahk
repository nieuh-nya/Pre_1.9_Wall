#NoEnv
#Include settings.ahk
SetKeyDelay, 0

MousePosToInstNumber() {
  MouseGetPos, mX, mY
  return (Floor(mY / instHeight) * cols) + Floor(mX / instWidth) + 1
}

GetIdleFile(idx) {
  Return McDirectories[idx] . "idle.tmp"
}

CountAttempts() {
  FileRead, Attempt, ATTEMPTS.txt
  if (ErrorLevel) {
    Attempt := 0
  }
  else {
    FileDelete, ATTEMPTS.txt
  }
  Attempt += 1
  FileAppend, %Attempt%, ATTEMPTS.txt

  FileRead, Attempt, ATTEMPTS_DAY.txt
  if (ErrorLevel) {
    Attempt = 0
  } else {
    FileDelete, ATTEMPTS_DAY.txt
  }
  Attempt += 1
  FileAppend, %Attempt%, ATTEMPTS_DAY.txt
}

RunHide(command) {
  dhw := A_DetectHiddenWindows
  DetectHiddenWindows, On
  Run, %ComSpec%,, Hide, cPid
  WinWait, ahk_pid %cPid%
  DetectHiddenWindows, %dhw%
  DllCall("AttachConsole", "uint", cPid)

  shell := ComObjCreate("WScript.Shell")
  exec := shell.Exec(command)
  result := exec.StdOut.ReadAll()

  DllCall("FreeConsole")
  Process, Close, %cPid%
  Return result
}

GetMcDir(pid) {
  command := Format("powershell.exe $x = Get-WmiObject Win32_Process -Filter \""ProcessId = {1}\""; $x.CommandLine", pid)
  rawOut := RunHide(command)
  if (InStr(rawOut, "--gameDir")) {
    strStart := RegExMatch(rawOut, "P)--gameDir (?:""(.+?)""|([^\s]+))", strLen, 1)
    return SubStr(rawOut, strStart+10, strLen-10) . "\"
  } 
  else {
    strStart := RegExMatch(rawOut, "P)(?:-Djava\.library\.path=(.+?) )|(?:\""-Djava\.library.path=(.+?)\"")", strLen, 1)
    if (SubStr(rawOut, strStart+20, 1) == "=") {
      strLen -= 1
      strStart += 1
    }
    return StrReplace(SubStr(rawOut, strStart+20, strLen-28) . ".minecraft\", "/", "\")
  }
}

GetInstanceTotal() {
  idx := 1
  WinGet, all, list
  loop, %all% {
    WinGet, pid, PID, % "ahk_id " all%A_Index%
    WinGetTitle, title, ahk_pid %pid%
    if (InStr(title, "Minecraft 1.8.9")) {
      rawPIDs[idx] := pid
      idle[idx] := True
      idx += 1
    }
  }
  return rawPIDs.MaxIndex()
}

GetInstanceNumberFromMcDir(mcdir) {
  numFile := mcdir . "instanceNumber.txt"
  num := -1
  if (!FileExist(numFile)) {
    MsgBox, Missing instanceNumber.txt in %mcdir%
  }
  else {
    FileRead, num, %numFile%
  }
  return num
}

GetAllPIDs() {
  instances := GetInstanceTotal()
  loop, %instances% {
    mcdir := GetMcDir(rawPIDs[A_Index])
    if ((num := GetInstanceNumberFromMcDir(mcdir)) == -1) {
      ExitApp
    }
    PIDs[num] := rawPIDs[A_Index]
    McDirectories[num] := mcdir
  }
}

SetTitles() {
  for i, pid in PIDs {
    WinSetTitle, ahk_pid %pid%, , Minecraft 1.8.9 - Instance %i%
  }
}

GetActiveInstanceNum() {
  WinGet, pid, PID, A
  WinGetTitle, title, ahk_pid %pid%
  if (InStr(title, "Minecraft 1.8.9 - Instance ")) {
    for i, tmppid in PIDs {
      if (tmppid == pid) {
        return i
      }
    }
  }
  return -1
}

ToWall() {
  WinMaximize, Fullscreen Projector
  WinActivate, Fullscreen Projector
  send {F12 down}
  sleep, %obsDelay%
  send {F12 up}
}

ExitWorld() {
  if ((idx := GetActiveInstanceNum()) > 0 && FileExist(GetIdleFile(idx))) {
    pid := PIDs[idx]
    if (wideResets) {
      newHeight := Floor(A_ScreenHeight / widthMultiplier)
      WinRestore, ahk_pid %pid%
      WinMove, ahk_pid %pid%,,0,0,%A_ScreenWidth%,%newHeight%
    }
    ToWall()
    ResetInstance(idx, True)
  }
}

SwitchInstance(idx)
{
  if (idx <= instances && FileExist(GetIdleFile(idx))) {
    idleFile := GetIdleFile(idx)
    FileDelete, %idleFile%
    locked[idx] := true
    pid := PIDs[idx]
    if(switchToEasy) {
      SwitchToEasy(pid)
    }
    if(renderDistanceOnJoin) {
      ChangeRenderOnJoin(pid)
    }
    if(coop) {
      OpenToLan(pid)
    }
    if (wideResets) {
      WinMaximize, ahk_pid %pid%
    }
    WinActivate, ahk_pid %pid%
    WinMinimize, Fullscreen Projector
    if(unpauseOnJoin && !coop) {
      if(switchToEasy || renderDistanceOnJoin) {
        sleep %guiDelay%
      }
      ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
    }
    FileAppend,, %idleFile%
    send {Numpad%idx% down}
    sleep, %obsDelay%
    send {Numpad%idx% up}
  }
}

ResetInstance(idx, resetSettings := False) {
  if (idx > 0 && idx <= instances && FileExist(GetIdleFile(idx))) {
    idleFile := GetIdleFile(idx)
    FileDelete, %idleFile%
    locked[idx] := false
    pid := PIDs[idx]
    Run, %A_ScriptDir%\scripts\reset.ahk %pid% %resetSettings% %idleFile%
    if(countAttempts) {
      CountAttempts()
    }
  }
}

LockInstance(idx) {
  locked[idx] := true
  if (lockSounds) {
    SoundPlay, A_ScriptDir\..\media\lock.wav
  }
}

FocusReset(focusInstance) {
  if(fastFocusReset) {
    loop, %instances% {
      if (A_Index != focusInstance && !locked[A_Index]) {
        ResetInstance(A_Index)
      }
    }
    SwitchInstance(focusInstance)
  }
  else {
    SwitchInstance(focusInstance)
    loop, %instances% {
      if (A_Index != focusInstance && !locked[A_Index]) {
        ResetInstance(A_Index)
      }
    }
  }
}

ResetAll() {
  loop, %instances% {
    if (!locked[A_Index]) {
      ResetInstance(A_Index)
    }
  }
}

SwitchToEasy(pid) {
  ControlSend, ahk_parent, {Blind}{Tab 3}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab 2}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter 3}, ahk_pid %pid%
  sleep %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Tab 12}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
}

ChangeRenderOnJoin(pid) {
  if(switchToEasy) {
    sleep %guiDelay%
  }
  ControlSend, ahk_parent, {Blind}{Tab 3}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab 8}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab 2}, ahk_pid %pid%
  sleep %settingsDelay%
  RDPresses := renderDistanceOnJoin - renderDistance
  ControlSend, ahk_parent, {Blind}{Right %RDPresses%}, ahk_pid %pid%
  sleep %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Tab 17}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab 14}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
}

OpenToLan(pid) {
  if(switchToEasy || renderDistanceOnJoin) {
    sleep %guiDelay%
  }
  ControlSend, ahk_parent, {Blind}{Tab 4}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab 4}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
}