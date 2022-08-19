#NoEnv
#SingleInstance Force
#Include %A_ScriptDir%\scripts\utils.ahk
#Include %A_ScriptDir%\settings.ahk

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
global instanceManagerPIDs := []
global minecraftDirectories := []

FileDelete, ATTEMPTS_DAY.txt
FileDelete, activeInstance.txt
FileDelete, log*.txt
SetupInstances()

SetupInstances() {
	titleFormat := "Minecraft " . version
	WinGet, allInstances, list, %titleFormat%
	loop, %allInstances% {
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
            FileAppend, Found valid instance %instanceNumber% with windowID = %windowID% and PID = %PID%`n, log.txt
			if (tmpID := instanceManagerPIDs[instanceNumber]) {
                DetectHiddenWindows, On
				PostMessage, MSG_UPDATE_PID, PID,,, ahk_pid %tmpID%
                DetectHiddenWindows, Off
                FileAppend, Instance Manager already exists - sent MSG_UPDATE_PID`n, log.txt
			}
			else {
				Run, "%A_ScriptDir%\scripts\instance_manager.ahk" %instanceNumber% %windowID% %PID% %minecraftDirectory%,,, instanceManagerPID
                DetectHiddenWindows, On
                WinWait, ahk_pid %instanceManagerPID%
                DetectHiddenWindows, Off
                instanceManagerPIDs[instanceNumber] := instanceManagerPID
                FileAppend, Started Instance Manager with PID = %instanceManagerPID%`n, log.txt
			}
		}
	}
    totalInstances := PIDs.MaxIndex()
    FileAppend, Found %totalInstances% instances`n, log.txt
	if (!disableTTS) {
		ComObjCreate("SAPI.SpVoice").Speak("Ready")
	}
}

LockInstance(instanceNumber) {
	if (instanceNumber > 0 && instanceNumber <= totalInstances) {
		instanceManagerPID := instanceManagerPIDs[instanceNumber]
        DetectHiddenWindows, On
		PostMessage, MSG_LOCK,,,, ahk_pid %instanceManagerPID%
        DetectHiddenWindows, Off
	}
}

PlayInstance(instanceNumber) {
    if (instanceNumber > 0 && instanceNumber <= totalInstances) {
        instanceManagerPID := instanceManagerPIDs[instanceNumber]
        DetectHiddenWindows, On
        PostMessage, MSG_PLAY,,,, ahk_pid %instanceManagerPID%
        DetectHiddenWindows, Off
    }
}

ResetInstance(instanceNumber, ignoreLock) {
    FileAppend, ResetInstance(%instanceNumber% %ignoreLock%)`n, log.txt
	if (instanceNumber > 0 && instanceNumber <= totalInstances) {
		instanceManagerPID := instanceManagerPIDs[instanceNumber]
        DetectHiddenWindows, On
		PostMessage, MSG_RESET, ignoreLock,,, ahk_pid %instanceManagerPID%
        DetectHiddenWindows, Off
        FileAppend, Sent MSG_RESET with ignoreLock = %ignoreLock% to instance %instanceNumber% with instanceManagerPID %instanceManagerPID%`n, log.txt
	}
}

ResetAll() {
	Loop, %totalInstances% {
		ResetInstance(A_Index, False)
	}
}

FocusReset(focusInstance) {
	PlayInstance(focusInstance)
    Sleep, %focusResetDelay%
    Loop, %totalInstances% {
        if(A_Index != focusInstance) {
            ResetInstance(A_Index, False)
        }
    }
}

MousePosToInstanceNumber() {
	MouseGetPos, mouseX, mouseY
	return (Floor(mouseY / instanceHeight) * columns) + Floor(mouseX / instanceWidth) + 1
}

#Persistent
OnExit("HandleExit")

HandleExit(ExitReason) {
    FileAppend, Exiting, log.txt
    if ExitReason not in Logoff,Shutdown
    {
        DetectHiddenWindows, On
        totalInstanceManagers := instanceManagerPIDs.MaxIndex()
        FileAppend, Exiting and Closing %totalInstanceManagers% instanceManagers`n, log.txt
        Loop, %totalInstanceManagers% {
            instanceManagerPID := instanceManagerPIDs[A_Index]
            WinClose, ahk_pid %instanceManagerPID%
            FileAppend, Closed instanceManager%A_Index% with PID: %instanceManagerPID%`n, log.txt
        }
        DetectHiddenWindows, Off
    }
}

#Include %A_ScriptDir%\hotkeys.ahk