#NoEnv
#NoTrayIcon
#SingleInstance, Off

#include %A_ScriptDir%\..\settings.ahk
#include %A_ScriptDir%\utils.ahk

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

global instanceNumber := A_Args[1]
global windowID := A_Args[2]
global PID := A_Args[3]
global mainScriptPID := A_Args[4]

global MSG_RESET := 0x1001
global MSG_LOCK := 0x1002
global MSG_PLAY := 0x1003
global MSG_CHANGED_ACTIVE_INSTANCE := 0x1004
global MSG_STARTED_PLAYING := 0x1005
global MSG_STOPPED_PLAYING := 0x1006
OnMessage(MSG_RESET, "HandleReset")
OnMessage(MSG_LOCK, "HandleLock")
OnMessage(MSG_PLAY, "HandlePlay")
OnMessage(MSG_CHANGED_ACTIVE_INSTANCE, "HandleChangedActiveInstance")

EnvGet, totalThreads, NUMBER_OF_PROCESSORS
global currentThreads := totalThreads
global playThreads := playThreadsOverride > 0 ? playThreadsOverride : totalThreads
global resettingThreads := resettingThreadsOverride > 0 ? resettingThreadsOverride : totalThreads
global resettingBackgroundThreads := resettingBackgroundThreadsOverride > 0 ? resettingBackgroundThreadsOverride : Ceil(totalThreads * 0.66)
global idleThreads := idleThreadsOverride > 0 ? idleThreadsOverride : Ceil(totalThreads * 0.5)
global idleBackgroundThreads := idleBackgroundThreadsOverride > 0 ? idleBackgroundThreadsOverride : Ceil(totalThreads * 0.33)
global lockedThreads := idleThreads
global lockedBackgroundThreads := idleBackgroundThreads

RegExMatch(version, "\d\.(\d+)\.\d", Match)
global subVersion := Match1 + 0
global ahkControl := "ahk_parent"
if (subVersion == 3) {
	ahkControl := "LWJGL1"
}

global locked := False
global oldState := "idle"
global state := "idle" ; possible states: idle, resetting, preparingToPlay, playing
global stateOutFile := GetMinecraftDirectory(PID) . "wpstateout.txt" ; for 1.3
global lastPauseTime := 0
global activeInstanceNumber := 0
global tabPresses := 1
if (subVersion == 8) {
	tabPresses = 7
}

thisPID := DllCall("GetCurrentProcessId")
SendLog(Format("This instanceManager's PID is {1}", thisPID))

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

HandleReset(ignoreLock) {
	SendLog("Received MSG_RESET")
	Critical, On
	if (locked && !ignoreLock) {
		SendLog("Not resetting because instance is locked")
		return
	}
	else if (state == "idle" || state == "playing") {
		SetState("resetting")
		locked := False
		Critical, Off
		SendLog(Format("Reset is valid with oldState = {1}", oldState))

		if (oldState == "playing") {
			if (!useAtumHotkey) {
				SendLog("Switching to pause menu")
				ControlSend, %ahkControl%, {Blind}{Esc}, ahk_pid %PID%
			}
			if (affinity) {
				SendLog("Sending MSG_STOPPED_PLAYING")
				activeInstanceNumber := 0
				DetectHiddenWindows, On
				PostMessage, MSG_STOPPED_PLAYING, instanceNumber,,, ahk_pid %mainScriptPID%
				DetectHiddenWindows, Off
			}
			if (wideResets) {
				MakeWindowWide(windowID, widthMultiplier)
			}
			Send, {%obsWallSceneKey% down}
			Sleep, %obsDelay%
			Send, {%obsWallSceneKey% up}
			WinActivate, screen Projector
		}

		if (resetSounds) {
			SoundPlay, %A_ScriptDir%\..\media\reset.wav
		}

		if (useAtumHotkey) {
			SendLog(Format("Sending atumHotkey = {1}", atumHotkey))
			ControlSend, %ahkControl%, {Blind}{%atumHotkey% down}, ahk_pid %PID%
			Sleep, %resetDownDelay%
			ControlSend, %ahkControl%, {Blind}{%atumHotkey% up}, ahk_pid %PID%
		}
		else {
			; guarantee that guiDelay has passed before resetting
			if (A_TickCount - lastPauseTime < guiDelay) {
				timeToSleep := guiDelay - (A_TickCount - lastPauseTime)
				SendLog(Format("Waiting an extra {1}ms", timeToSleep))
				Sleep, %timeToSleep%
			}
			SendLog(Format("Sending reset inputs with Tab x {1}", tabPresses))
			ControlSend, %ahkControl%, {Blind}{Tab %tabPresses%}, ahk_pid %PID%
			Sleep, %settingsDelay%
			ControlSend, %ahkControl%, {Blind}{Enter}, ahk_pid %PID%
		}

		if (subVersion == 3) {
			; wait until out of current world
			SendLog(Format("stateOutFile = {1}", stateOutFile))
			while (True) {
				FileRead, stateOut, %stateOutFile%
				SendLog(Format("Read line: {1}", stateOut))
				if (InStr(stateOut, "waiting") || InStr(stateOut, "generating")) {
					break
				}
				Sleep, %stateOutReadDelay%
			}
			Sleep, %worldLoadDelay%
			
			; wait until in next world
			while (True) {
				FileRead, stateOut, %stateOutFile%
				SendLog(Format("Read line: {1}", stateOut))
				if (InStr(stateOut, "inworld")) {
					break
				}
				Sleep, %stateOutReadDelay%
			}
		}
		else {
			; check for loading screen
			while (True) {
				color := GetTopLeftPixelColor(windowID)
				SendLog(Format("Got pixel : {1}", color))
				if (color == loadingScreenColor) {
					break
				}
				Sleep, %pixelCheckDelay%
			}
			Sleep, %worldLoadDelay%
	
			; check for world load
			while (True) {
				color := GetTopLeftPixelColor(windowID)
				SendLog(Format("Got pixel : {1}", color))
				if (color != loadingScreenColor) {
					break
				}
				Sleep, %pixelCheckDelay%
			}
			Sleep, %titleScreenFlashDelay%
		
			; second check for world load in case title screen flashed
			while (True) {
				color := GetTopLeftPixelColor(windowID)
				SendLog(Format("Got pixel : {1}", color))
				if (color != loadingScreenColor) {
					break
				}
				Sleep, %pixelCheckDelay%
			}
		}

		Sleep, %beforePauseDelay%
		ControlSend, %ahkControl%, {Blind}{Esc}, ahk_pid %PID%
		SetState("idle")
		lastPauseTime := A_TickCount
		SendLog(Format("Paused at {1}", lastPauseTime))
	}
	else {
		Critical, Off
		SendLog(Format("Not resetting because state = {1}", state))
	}
}

HandleLock() {
	SendLog("Received MSG_LOCK")
	Critical, On
	if (state == "idle") {
		locked := True
		Critical, Off
		HandleAffinity()
		if (lockSounds) {
			SoundPlay, %A_ScriptDir%\..\media\lock.wav
		}
		SendLog("Done locking")
	}
	else {
		Critical, Off
		SendLog(Format("Not locking because state = {1}", state))
	}
}

HandlePlay() {
	SendLog("Received MSG_PLAY")
	Critical, On
	if (state == "idle") {
		SetState("preparingToPlay")
		locked := False
		Critical, Off

		if (affinity) {
			SendLog("Sending MSG_STARTED_PLAYING")
			activeInstanceNumber := instanceNumber
			DetectHiddenWindows, On
			PostMessage, MSG_STARTED_PLAYING, instanceNumber,,, ahk_pid %mainScriptPID%
			DetectHiddenWindows, Off
		}

		if (wideResets) {
			WinMaximize, ahk_id %windowID%
		}
		WinActivate, ahk_id %windowID%
		WinMinimize, screen Projector

		MouseMove, A_ScreenWidth/2 + 1, A_ScreenHeight/2 + 1, 0 ; Removes cursor twitching

		if (switchToEasy && subVersion >= 8) {
			SendLog("Switching to easy")
			ControlSend, %ahkControl%, {Blind}{Tab 3}, ahk_pid %PID%
			Sleep, %settingsDelay%
			ControlSend, %ahkControl%, {Blind}{Enter}, ahk_pid %PID%
			Sleep %guiDelay%
			ControlSend, %ahkControl%, {Blind}{Tab 2}, ahk_pid %PID%
			Sleep, %settingsDelay%
			ControlSend, %ahkControl%, {Blind}{Enter 3}, ahk_pid %PID%
			Sleep %settingsDelay%
			tabsToDone := 12
			if (subVersion >= 10) {
				tabsToDone := 10
			}
			ControlSend, %ahkControl%, {Blind}{Tab %tabsToDone%}, ahk_pid %PID%
			Sleep, %settingsDelay%
			ControlSend, %ahkControl%, {Blind}{Enter}, ahk_pid %PID%
		}

		if (unpauseOnJoin) {
			if (switchToEasy) {
				Sleep, %guiDelay%
			}
			ControlSend, %ahkControl%, {Blind}{Esc}, ahk_pid %PID%
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

HandleChangedActiveInstance(newActiveInstanceNumber) {
	SendLog(Format("Received MSG_CHANGED_ACTIVE_INSTANCE with newActiveInstanceNumber = {1}", newActiveInstanceNumber))
	activeInstanceNumber := newActiveInstanceNumber
	HandleAffinity()
}

SetState(newState) {
	oldState := state
	state := newState
	SendLog(Format("Set state to {1}", state))
	HandleAffinity()
}

HandleAffinity() {
	if (affinity) {
		isBackgroundInstance := activeInstanceNumber > 0

		if (state == "preparingToPlay" || state == "playing") {
			newThreads := playThreads
		}
		else if (locked) {
			if (isBackgroundInstance) {
				newThreads := lockedBackgroundThreads
			}
			else {
				newThreads := lockedThreads
			}
		}
		else if (state == "resetting") {
			if (isBackgroundInstance) {
				newThreads := resettingBackgroundThreads
			}
			else {
				newThreads := resettingThreads
			}
		}
		else if (state == "idle") {
			if (isBackgroundInstance) {
				newThreads := idleBackgroundThreads
			}
			else {
				newThreads := idleThreads
			}
		}

		if (newThreads != currentThreads) {
			SetAffinity(newThreads)
		}
	}
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