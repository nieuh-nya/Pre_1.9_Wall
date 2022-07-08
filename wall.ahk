#NoEnv
#SingleInstance Force
#Include %A_ScriptDir%\scripts\functions.ahk
#Include settings.ahk

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

global instWidth := Floor(A_ScreenWidth / cols)
global instHeight := Floor(A_ScreenHeight / rows)
global McDirectories := []
global instances := 0
global rawPIDs := []
global PIDs := []
global resetIdx := []
global locked := []

GetAllPIDs()
SetTitles()
FileDelete, ATTEMPTS_DAY.txt

for i, mcdir in McDirectories {
  pid := PIDs[i]
  WinRestore, ahk_pid %pid%
  if (borderless) {
    WinSet, Style, -0xC00000, ahk_pid %pid%
    WinSet, Style, -0x40000, ahk_pid %pid%
    WinSet, ExStyle, -0x00000200, ahk_pid %pid%
  }
  if (wideResets) {
    WinMove, ahk_pid %pid%,, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%
    newHeight := Floor(A_ScreenHeight / widthMultiplier)
    WinMove, ahk_pid %pid%,, 0, 0, %A_ScreenWidth%, %newHeight%
  }
  else {
    WinMaximize, ahk_pid %pid%
  }
  idleFile := mcdir . "idle.tmp"
  if (!FileExist(idleFile)) {
    FileAppend,, %idleFile%
  }
}

if (!disableTTS) {
  ComObjCreate("SAPI.SpVoice").Speak("Ready")
}

#Include hotkeys.ahk