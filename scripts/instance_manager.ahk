#NoEnv
#NoTrayIcon
#SingleInstance, off
#include %A_ScriptDir%\..\settings.ahk
#include %A_ScriptDir%\utils.ahk
SetKeyDelay, 0
SetWinDelay, 1

global MSG_RESET := 0x0401
global MSG_LOCK := 0x0402
global MSG_PLAY := 0x0403
global MSG_UPDATE_PID := 0x0404

global locked := False
global state := "idle" ; possible states: idle, resetting, preparingToPlay, playing

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
global minecraftDirectory := A_Args[4]

OnMessage(MSG_RESET, "HandleReset", 2)
OnMessage(MSG_LOCK, "HandleLock", 1)
OnMessage(MSG_PLAY, "HandlePlay", 2)
OnMessage(MSG_UPDATE_PID, "HandleUpdatePID", 1)

SetupInstance()

while (affinity) {
    Sleep, %affinityCheckDelay%
    if (state == "playing") {
        continue
    }
    Critical, On
    activeInstanceNumber := GetActiveInstanceNumber()
    newThreads := 0
    if (activeInstanceNumber && activeInstanceNumber != instanceNumber) {
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
    FileAppend, state = %state%`n, log%instanceNumber%.txt
}

HandleReset(ignoreLock) {
    FileAppend, HandleReset(%ignoreLock%)`n, log%instanceNumber%.txt
	Critical, On
	if (locked && !ignoreLock) {
        FileAppend, Instance is locked, cancelling reset`n, log%instanceNumber%.txt
		return
	}
	else if (state == "idle" || state == "playing") {
		oldState := state
		state := "resetting"
		Critical, Off
        activeInstanceNumber := GetActiveInstanceNumber()
        if (activeInstanceNumber && activeInstanceNumber != instanceNumber) {
            SetAffinity(lowThreads)
        }
        else {
            SetAffinity(highThreads)
        }
        FileAppend, Valid reset with oldState = %oldState%`n, log%instanceNumber%.txt
        FileAppend, state = %state%`n, log%instanceNumber%.txt
        locked := false

		if (oldState == "playing") {
            FileAppend, Exiting world`n, log%instanceNumber%.txt
			if (wideResets) {
				MakeWindowWide(windowID, widthMultiplier)
			}
			WinActivate, Fullscreen Projector
			Send, {%obsWallSceneKey% down}
			Sleep, %obsDelay%
			Send, {%obsWallSceneKey% up}
            FileDelete, %A_ScriptDir%\..\activeInstance.txt
		}

		if (%resetSounds%) {
			SoundPlay, A_ScriptDir\..\media\reset.wav
		}
		TabPresses := 7 ; magically works for everything

		; reset whether paused or unpaused
		ControlSend, ahk_parent, {Blind}{Tab %TabPresses%}, ahk_pid %PID%
        Sleep, %settingsDelay%
        ControlSend, ahk_parent, {Blind}{Enter}{Esc}, ahk_pid %PID%
		Sleep, %guiDelay%
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
        } 
        else {
            FileDelete, ATTEMPTS_DAY.txt
        }
        Attempt += 1
        FileAppend, %Attempt%, ATTEMPTS_DAY.txt

		state := "idle"
        if (GetActiveInstanceNumber()) {
            SetAffinity(superLowThreads)
        }
        else {
            SetAffinity(lowThreads)
        }
        FileAppend, Reset complete and state = %state%`n, log%instanceNumber%.txt
	}
    else {
        FileAppend, Cancelling reset because state = %state%`n, log%instanceNumber%.txt
    }
}

HandleLock() {
    FileAppend, HandleLock()`n, log%instanceNumber%.txt
	Critical, On
	if (state == "idle") {
        FileAppend, state = %state% and locking instance`n, log%instanceNumber%.txt
		locked := True
        if (GetActiveInstanceNumber()) {
            SetAffinity(superLowThreads)
        }
        else {
            SetAffinity(lockThreads)
        }
		if (lockSounds) {
			SoundPlay, A_ScriptDir\..\media\lock.wav
		}
	}
    else {
        FileAppend, Cancelling lock because state = %state%`n, log%instanceNumber%.txt
    }
}

HandlePlay() {
    FileAppend, HandlePlay()`n, log%instanceNumber%.txt
	Critical, On
	if (state == "idle" && !GetActiveInstanceNumber()) {
		state := "preparingToPlay"
		Critical, Off
        SetAffinity(playThreads)
        FileAppend, %instanceNumber%, A_ScriptDir\..\activeInstance.txt
        FileAppend, Switching to instance and state = %state%`n, log%instanceNumber%.txt
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
		WinActivate, ahk_id %windowID%
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
        FileAppend, Done switching and state = %state%`n, log%instanceNumber%.txt
	}
    else {
        FileAppend, Cancelling play because state = %state%`n, log%instanceNumber%.txt
    }
}

HandleUpdatePID(newPID) {
    FileAppend, HandleUpdatePID(%newPID%)`n, log%instanceNumber%.txt
	WinGet, windowID, ID, ahk_pid %PID%
	SetupInstance()
}

SetAffinity(threadCount) {
    bitMask := GetBitMask(threadCount)
    hProc := DllCall("OpenProcess", "UInt", 0x0200, "Int", false, "UInt", PID, "Ptr")
	DllCall("SetProcessAffinityMask", "Ptr", hProc, "Ptr", bitMask)
	DllCall("CloseHandle", "Ptr", hProc)
    currentThreads := threadCount
    FileAppend, Set Affinity to %threadCount%`n, log%instanceNumber%.txt
}