#NoEnv
#NoTrayIcon
#SingleInstance, Off
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

OnMessage(MSG_RESET, "HandleReset")
OnMessage(MSG_LOCK, "HandleLock")
OnMessage(MSG_PLAY, "HandlePlay")
OnMessage(MSG_UPDATE_PID, "HandleUpdatePID")

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
	SetState("idle")
    SendLog("Done setting up instance")
}

HandleReset(ignoreLock) {
    SendLog(Format("Received MSG_RESET with ignoreLock = {1}", ignoreLock))
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
            SendLog("Exiting world")
			if (wideResets) {
				MakeWindowWide(windowID, widthMultiplier)
			}
			WinActivate, Fullscreen Projector
			Send, {%obsWallSceneKey% down}
			Sleep, %obsDelay%
			Send, {%obsWallSceneKey% up}
            FileDelete, %A_ScriptDir%\..\activeInstance.txt
            ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %PID%
			Sleep, %guiDelay%
		}

		if (%resetSounds%) {
			SoundPlay, A_ScriptDir\..\media\reset.wav
		}
		TabPresses := 7 ; magically works for everything

        SendLog("Sending reset inputs")
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
        SendLog("Loading screen check successful")
		Sleep, %worldLoadDelay%

		; check for world load
		while (True) {
			if (GetTopLeftPixelColor(windowID) != loadingScreenColor) {
				break
			}
			Sleep, %pixelCheckDelay%
		}
        SendLog("First joined check successful")
		Sleep, %titleScreenFlashDelay%

		; second check for world load in case title screen flashed
		while (True) {
			if (GetTopLeftPixelColor(windowID) != loadingScreenColor) {
				break
			}
			Sleep, %pixelCheckDelay%
		}
        SendLog("Second joined check successful")

		Sleep, %beforePauseDelay%
		ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %PID%
        SendLog("Pausing game")

        if (countAttempts) {
            FileRead, %Attempts%, %A_ScriptDir%\..\ATTEMPTS.txt
            if (!ErrorLevel) {
                Attempts++
                FileDelete, %A_ScriptDir%\..\ATTEMPTS.txt
                FileAppend, %Attempts%, %A_ScriptDir%\..\ATTEMPTS.txt
                SendLog(Format("Increased ATTEMPTS to {1}", Attempts))
            }
            else {
                SendLog("Could not read ATTEMPTS.txt")
            }

            FileRead, %AttemptsSession%, %A_ScriptDir%\..\ATTEMPTS_SESSION.txt
            if (!ErrorLevel) {
                AttemptsSession++
                FileDelete, %A_ScriptDir%\..\ATTEMPTS_SESSION.txt
                FileAppend, %AttemptsSession%, %A_ScriptDir%\..\ATTEMPTS_SESSION.txt
                SendLog(Format("Increased ATTEMPTS_SESSION to {1}", AttemptsSession))
            }
            else {
                SendLog("Could not read ATTEMPTS_SESSION.txt")
            }
        }

		SetState("idle")
        SendLog("Done resetting")
	}
    else {
        SendLog(Format("Not resetting because state = {1}", state))
    }
}

HandleLock() {
    SendLog("Received MSG_LOCK")
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
    SendLog("Received MSG_PLAY")
    Critical, On
	if (state == "idle") {
		SetState("preparingToPlay")
        FileAppend, %instanceNumber%, A_ScriptDir\..\activeInstance.txt
        Critical, Off
        SendLog(Format("Started switching to playing"))
        SetAffinity(playThreads)
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
		SetState("playing")
        SendLog("Done switching to playing")
	}
    else {
        SendLog(Format("Not switching to playing because state = {1}", state))
    }
}

HandleUpdatePID(newPID) {
    SendLog(Format("Received MSG_UPDATE_PID with newPID = {1}", newPID))
	WinGet, windowID, ID, ahk_pid %PID%
    SendLog(Format("New windowID is {2}", windowID))
	SetupInstance()
}

SetState(newState) {
    state := newState
    SendLog(Format("Set state to {1}", state))
}

SetAffinity(threadCount) {
    bitMask := GetBitMask(threadCount)
    hProc := DllCall("OpenProcess", "UInt", 0x0200, "Int", false, "UInt", PID, "Ptr")
	DllCall("SetProcessAffinityMask", "Ptr", hProc, "Ptr", bitMask)
	DllCall("CloseHandle", "Ptr", hProc)
    currentThreads := threadCount
    SendLog(Format("Set affinity to {1}", threadCount))
}

SendLog(message) {
    if (logging) {
        FileAppend, [%A_TickCount%] [%A_YYYY-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%] [INSTANCE-%instanceNumber%] %message%`n, %A_ScriptDir%\..\log.txt
    }
}