#NoEnv
#Include settings.ahk
SetKeyDelay, 0

PixelColorSimple(pc_x, pc_y, pc_wID) {
  if pc_wID {
    pc_hDC := DllCall("GetDC", "UInt", pc_wID)
    pc_fmtI := A_FormatInteger
    SetFormat, IntegerFast, Hex
    pc_c := DllCall("GetPixel", "UInt", pc_hDC, "Int", pc_x, "Int", pc_y, "UInt")
    pc_c := pc_c >> 16 & 0xff | pc_c & 0xff00 | (pc_c & 0xff) << 16
    pc_c .= ""
    SetFormat, IntegerFast, %pc_fmtI%
    DllCall("ReleaseDC", "UInt", pc_wID, "UInt", pc_hDC)
    return pc_c
  }
}

getHwndForPid(pid) {
  pidStr := "ahk_pid " . pid
  WinGet, hWnd, ID, %pidStr%
  return hWnd
}

pid = %1%
resetSettings = %2%
idleFile = %3%

ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid% ; close chat
sleep, %settingsDelay%
if(resetSettings && renderDistance) {
	RDPresses := renderDistance - 2
  ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
  sleep, %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab 3}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep, %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab 8}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep, %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab 2}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Left 30}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Right %RDPresses%}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Tab 17}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep, %guiDelay%
  ControlSend, ahk_parent, {Blind}{Tab 14}, ahk_pid %pid%
  sleep, %settingsDelay%
  ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid%
  sleep, %guiDelay%
}

if (%resetSounds%) {
  SoundPlay, A_ScriptDir\..\media\reset.wav
}

; reset whether paused or unpaused (only works if not resetting render)
ControlSend, ahk_parent, {Blind}{Tab 7}{Enter}, ahk_pid %pid%
ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
sleep, %guiDelay%
ControlSend, ahk_parent, {Blind}{Tab 7}{Enter}, ahk_pid %pid%

; check for loading screen
while (True) {
  p := PixelColorSimple(0, 0, getHwndForPid(pid))
  if(p == 0x2E2117) {
    break
  }
}
; check for ingame
while (True) {
  p := PixelColorSimple(0, 0, getHwndForPid(pid))
  if (p != 0x2E2117) {
    break
  }
}
sleep, 500
; second check in case title screen flashed
while (True) {
  p := PixelColorSimple(0, 0, getHwndForPid(pid))
  if (p != 0x2E2117) {
    break
  }
}

sleep, %beforePauseDelay%
ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
FileAppend,, %idleFile%
ExitApp