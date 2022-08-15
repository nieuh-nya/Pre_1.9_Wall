#NoEnv
#SingleInstance Force
#Include %A_ScriptDir%\scripts\functions.ahk
#Include settings.ahk

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 1

global MSG_RESET := 0x0401
global MSG_LOCK := 0x0402
global MSG_PLAY := 0x0403
global MSG_UPDATE_PID := 0x0404

global instanceWidth := Floor(A_ScreenWidth / columns)
global instanceHeight := Floor(A_ScreenHeight / rows)
global totalInstances := 0

global windowIDs := []
global PIDs := []
global minecraftDirectories := []

FileDelete, ATTEMPTS_DAY.txt
SetupInstances()

SetupInstances() {
	titleFormat := "Minecraft " . version
	WinGet, allInstances, list, %titleFormat%
	loop, %all% {
		windowID := allInstances%A_Index%
		WinGet, PID, PID, ahk_id %windowID%
		minecraftDirectory := GetMinecraftDirectory(PID)
		instanceNumber := GetInstanceNumber(minecraftDirectory)
		if (instanceNumber == -1) {
			ExitApp
		}
		else if (PID == PIDs[instanceNumber] && windowID == windowIDs[instanceNumber]) {
			continue
		}
		else {
			windowIDs[instanceNumber] := windowID
			PIDs[instanceNumber] := PID
			MinecraftDirectories[instanceNumber] := minecraftDirectory
			if (instanceManagerPID := InstanceManagerPIDs[instanceNumber]) {
				PostMessage, MSG_UPDATE_PID, PID,,, ahk_pid %instanceManagerPID%
			}
			else {
				Run, "%A_ScriptDir%\scripts\instance_manager.ahk" %instanceNumber% %windowID% %PID% %minecraftDirectory%
			}
		}
	}
	if (!disableTTS) {
		ComObjCreate("SAPI.SpVoice").Speak("Ready")
	}
}

LockInstance(instanceNumber) {
	if (instanceNumber > 0 && instanceNumber <= totalInstances) {
		instanceManagerPID := instanceManagerPIDs[instanceNumber]
		PostMessage, MSG_LOCK,,, ahk_pid %instanceManagerPID%
	}
}

PlayInstance(instanceNumber) {
    if (instanceNumber > 0 && instanceNumber <= totalInstances) {
        instanceManagerPID := instanceManagerPIDs[instanceNumber]
        PostMessage, MSG_PLAY,,, ahk_pid %instanceManagerPID%
    }
}

ResetInstance(instanceNumber, ignoreLock) {
	if (instanceNumber > 0 && instanceNumber <= totalInstances) {
		instanceManagerPID := instanceManagerPIDs[instanceNumber]
		PostMessage, MSG_RESET, ignoreLock,, ahk_pid %instanceManagerPID%
	}
}

ResetAll() {
	Loop, %totalInstances% {
		ResetInstance(A_Index, False)
	}
}

FocusReset(focusInstance) {
	PlayInstance(focusInstance)
    Loop, %totalInstances% {
        if(A_Index != focusInstance) {
            ResetInstance(A_Index)
        }
    }
}

MousePosToInstanceNumber() {
	MouseGetPos, mouseX, mouseY
	return (Floor(mouseY / instanceHeight) * columns) + Floor(mouseX / instanceWidth) + 1
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
	} 
	else {
		FileDelete, ATTEMPTS_DAY.txt
	}
	Attempt += 1
	FileAppend, %Attempt%, ATTEMPTS_DAY.txt
}

#Include hotkeys.ahk