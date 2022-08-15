#NoEnv
#NoTrayIcon
#SingleInstance, off
#include settings.ahk
#include messages.ahk
#include functions.ahk
SetKeyDelay, 0

global MSG_RESET := 0x0401
global MSG_LOCK := 0x0402
global MSG_PLAY := 0x0403
global MSG_UPDATE_PID := 0x0404

global locked := False
global state := "idle" ; possible states: idle, resetting, preparingToPlay, playing

global instanceNumber := A_Args[1]
global windowID := A_Args[2]
global PID := A_Args[3]
global minecraftDirectory := A_Args[4]

OnMessage(MSG_RESET, "HandleReset", 2)
OnMessage(MSG_LOCK, "HandleLock", 1)
OnMessage(MSG_PLAY, "HandlePlay", 2)
OnMessage(MSG_UPDATE_PID, "HandleUpdatePID", 1)

SetupInstance() {
	WinSetTitle, ahk_pid %PID%, , Minecraft %version% - Instance %instanceNumber%
	WinRestore, ahk_pid %PID%
	if (borderless) {
		WinSet, Style, -0xC00000, ahk_pid %PID%
		WinSet, Style, -0x40000, ahk_pid %PID%
		WinSet, ExStyle, -0x00000200, ahk_pid %PID%
	}
	if (wideResets) {
		MakeWindowWide(windowID, widthMultiplier)
	}
	else {
		WinMaximize, ahk_pid %PID%
	}
	state := "idle"
}

HandleReset(ignoreLock) {
	Critical, On
	if (locked && !ignoreLock) {
		return
	}
	else if (state == "idle" || state == "playing") {
		oldState := state
		state := "resetting"
		Critical, Off

		if (oldState := "playing") {
			if (wideResets) {
				MakeWindowWide(windowID, widthMultiplier)
			}
			WinActivate, Fullscreen Projector
			Send, {%obsWallSceneKey% down}
			Sleep, %obsDelay%
			Send, {%obsWallSceneKey% up}
		}

		if (%resetSounds%) {
			SoundPlay, A_ScriptDir\..\media\reset.wav
		}
		TabPresses := 7 ; magically works for everything

		; reset whether paused or unpaused
		ControlSend, ahk_parent, {Blind}{Tab %TabPresses%}{Enter}, ahk_pid %PID%
		ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %PID%
		sleep, %guiDelay%
		ControlSend, ahk_parent, {Blind}{Tab %TabPresses%}{Enter}, ahk_pid %PID%

		; check for loading screen
		while (True) {
			if(GetTopLeftPixelColor(windowID) == loadingScreenColor) {
				break
			}
			sleep, %pixelCheckDelay%
		}
		sleep, %worldLoadDelay%

		; check for world load
		while (True) {
			if(GetTopLeftPixelColor(windowID) != loadingScreenColor) {
				break
			}
			sleep, %pixelCheckDelay%
		}
		sleep, %titleScreenFlashDelay%

		; second check for world load in case title screen flashed
		while (True) {
			if(GetTopLeftPixelColor(windowID) != loadingScreenColor) {
				break
			}
			sleep, %pixelCheckDelay%
		}

		sleep, %beforePauseDelay%
		ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %PID%
		state := idle
	}
}

HandleLock() {
	Critical, On
	if (state == "idle") {
		locked := True
		if (lockSounds) {
			SoundPlay, A_ScriptDir\..\media\lock.wav
		}
	}
}

HandlePlay() {
	Critical, On
	if (state == "idle") {
		state := "preparingToPlay"
		Critical, Off
		if (switchToEasy) {
			ControlSend, ahk_parent, {Blind}{Tab 3}, ahk_pid %PID%
			Sleep, %settingsDelay%
			ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %PID%
			Sleep %guiDelay%
			ControlSend, ahk_parent, {Blind}{Tab 2}, ahk_pid %PID%
			Sleep, %settingsDelay%
			ControlSend, ahk_parent, {Blind}{Enter 3}, ahk_pid %PID%
			Sleep %settingsDelay%
			ControlSend, ahk_parent, {Blind}{Tab 12}, ahk_pid %PID%
			Sleep, %settingsDelay%
			ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %PID%
		}
		if (wideResets) {
			WinMaximize, ahk_id %windowID%
		}
		else {
			WinActivate, ahk_id %windowID%
		}
		WinMinimize, Fullscreen Projector
		if (unpauseOnJoin) {
			if (switchToEasy) {
				Sleep, %guiDelay%
			}
			ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %PID%
		}
		if (obsSceneControlType == "N") {
			obsKey := "Numpad" . instanceNumber
		}
		else if (obsSceneControlType == "F") {
			obsKey := "F" . (instanceNumber + 12)
		}
		else {
			obsKey := obsCustomKeyArray[instanceNumber]
		}
		Send, {%obsKey% down}
		Sleep, %obsDelay%
		Send, {%obsKey% up}
		state := "playing"
	}
}

HandleUpdatePID(newPID) {
	WinGet, windowID, ahk_id, ahk_pid %PID%
	SetupInstance()
}
