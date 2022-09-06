#NoEnv
#NoTrayIcon
#SingleInstance, Off

#include %A_ScriptDir%\..\settings.ahk
#include %A_ScriptDir%\utils.ahk

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

global MSG_RESET := 0x0401
global MSG_LOCK := 0x0402
global MSG_PLAY := 0x0403

global locked := False
global state := "idle" ; possible states: idle, resetting, preparingToPlay, playing
global lastResetTime := A_TickCount

EnvGet, totalThreads, NUMBER_OF_PROCESSORS
global currentThreads := totalThreads
global playThreads := playThreadsOverride > 0 ? playThreadsOverride : totalThreads
global highThreads := highThreadsOverride > 0 ? highThreadsOverride : Max(Floor(totalThreads * 0.9), totalThreads - 4)
global lockThreads := lockThreadsOverride > 0 ? lockThreadsOverride : highThreads
global midThreads := midThreadsOverride > 0 ? midThreadsOverride : Ceil(totalThreads * 0.7)
global lowThreads := lowThreadsOverride > 0 ? lowThreadsOverride : Ceil(totalThreads * 0.5)
global superLowThreads := superLowThreadsOverride > 0 ? superLowThreadsOverride : Ceil(totalThreads * 0.2)

global instanceNumber := A_Args[1]
global windowID := A_Args[2]
global PID := A_Args[3]

OnMessage(MSG_RESET, "HandleReset")
OnMessage(MSG_LOCK, "HandleLock")
OnMessage(MSG_PLAY, "HandlePlay")

SetupInstance()

while (affinity) {
	Sleep, %affinityCheckDelay%

	if (state == "idle") {
		Critical, On
		newThreads := 0
		if (GetActiveInstanceNumber()) {
			newThreads := superLowThreads
		}
		else if (locked) {
			newThreads := lockThreads
		}
		else {
			newThreads := lowThreads
		}
		if (newThreads != currentThreads) {
			SetAffinity(newThreads)
		}
		Critical, Off
	}
}

SetupInstance() {
	WinSetTitle, ahk_id %windowID%, , Minecraft %version% - Instance %instanceNumber%
	WinRestore, ahk_id %windowID%
	if (borderless) {
		WinSet, Style, -0xC00000, ahk_id %windowID%
		WinSet, Style, -0x40000, ahk_id %windowID%
		WinSet, ExStyle, -0x00000200, ahk_id %windowID%
	}
	if (wideResets) {
		MakeWindowWide(windowID, widthMultiplier)
	}
	else {
		WinMaximize, ahk_id %windowID%
	}
	SetState("idle")
	SendLog("Done setting up instance")
}

HandleReset(ignoreLock) {
	Critical, On
	if (locked && !ignoreLock) {
		SendLog("Not resetting because instance is locked")
		return
	}
	else if (state == "idle" || state == "playing") {
		oldState := state
		SetState("resetting")
		locked := false
		Critical, Off

		SendLog(Format("Reset is valid with oldState = {1}", oldState))
		activeInstanceNumber := GetActiveInstanceNumber()
		if (activeInstanceNumber && activeInstanceNumber != instanceNumber) {
			SetAffinity(lowThreads)
		}
		else {
			SetAffinity(highThreads)
		}

		if (oldState == "playing") {
			if (wideResets) {
				MakeWindowWide(windowID, widthMultiplier)
			}
			WinActivate, screen Projector
			Send, {%obsWallSceneKey% down}
			Sleep, %obsDelay%
			Send, {%obsWallSceneKey% up}
			FileDelete, %A_ScriptDir%\..\activeInstance.txt
			ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %PID%
			Sleep, %guiDelay%
		}
		else {
			now := A_TickCount
			timeSinceLastReset := now - lastResetTime
			if (timeSinceLastReset < guiDelay) {
				Sleep, guiDelay - timeSinceLastReset
			}
		}

		if (%resetSounds%) {
			SoundPlay, A_ScriptDir\..\media\reset.wav
		}
		TabPresses := 7 ; magically works for everything

		ControlSend, ahk_parent, {Blind}{Tab %TabPresses%}, ahk_pid %PID%
		Sleep, %settingsDelay%
		ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %PID%

		; check for loading screen
		while (True) {
			if (GetTopLeftPixelColor(windowID) == loadingScreenColor) {
				break
			}
			Sleep, %pixelCheckDelay%
		}
		Sleep, %worldLoadDelay%

		; check for world load
		while (True) {
			if (GetTopLeftPixelColor(windowID) != loadingScreenColor) {
				break
			}
			Sleep, %pixelCheckDelay%
		}
		Sleep, %titleScreenFlashDelay%

		; second check for world load in case title screen flashed
		while (True) {
			if (GetTopLeftPixelColor(windowID) != loadingScreenColor) {
				break
			}
			Sleep, %pixelCheckDelay%
		}

		Sleep, %beforePauseDelay%
		ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %PID%
		lastResetTime := A_TickCount
		SetState("idle")
	}
	else {
		SendLog(Format("Not resetting because state = {1}", state))
	}
}

HandleLock() {
	Critical, On
	if (state == "idle") {
		locked := True
		Critical, Off
		if (lockSounds) {
			SoundPlay, A_ScriptDir\..\media\lock.wav
		}
		SendLog("Done locking")
	}
	else {
		SendLog(Format("Not locking because state = {1}", state))
	}
}

HandlePlay() {
	Critical, On
	if (state == "idle") {
		SetState("preparingToPlay")
		locked := False
		FileAppend, %instanceNumber%, A_ScriptDir\..\activeInstance.txt
		Critical, Off

		SetAffinity(playThreads)

		if (wideResets) {
			WinMaximize, ahk_id %windowID%
		}
		WinActivate, ahk_id %windowID%
		WinMinimize, screen Projector

		MouseMove, A_ScreenWidth/2 + 1, A_ScreenHeight/2 + 1, 0

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
		
		SetState("playing")
	}
	else {
		SendLog(Format("Not switching to playing because state = {1}", state))
	}
}

SetState(newState) {
	state := newState
	SendLog(Format("Set state to {1}", state))
}

SetAffinity(threadCount) {
	if (affinity) {
		bitMask := GetBitMask(threadCount)
		hProc := DllCall("OpenProcess", "UInt", 0x0200, "Int", false, "UInt", PID, "Ptr")
		DllCall("SetProcessAffinityMask", "Ptr", hProc, "Ptr", bitMask)
		DllCall("CloseHandle", "Ptr", hProc)
		currentThreads := threadCount
		SendLog(Format("Set affinity to {1}", threadCount))
	}
}

SendLog(message) {
	if (logging) {
		FileAppend, [%A_TickCount%] [%A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%] %message%`n, %A_ScriptDir%\..\logs\log_instance_%instanceNumber%.log
	}
}