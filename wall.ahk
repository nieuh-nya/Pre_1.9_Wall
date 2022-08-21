#NoEnv
#SingleInstance, Force
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

SendLog("Deleting temporary files")
FileDelete, ATTEMPTS_SESSION.txt
FileDelete, activeInstance.txt
FileDelete, log*.txt
if (countAttempts) {
    FileAppend, 0, %A_ScriptDir%\ATTEMPTS_SESSION.txt
    if (!FileExist("%A_ScriptDir%\ATTEMPTS.txt")) {
        FileAppend, 0, %A_ScriptDir%\ATTEMPTS.txt
    }
}
SetupInstances()

SetupInstances() {
    SendLog("Setting up instances")
    Send, {%obsWallSceneKey% down}
	Sleep, %obsDelay%
	Send, {%obsWallSceneKey% up}
	titleFormat := "Minecraft " . version
	WinGet, allInstances, list, %titleFormat%
	loop, %allInstances% {
		windowID := allInstances%A_Index%
		WinGet, PID, PID, ahk_id %windowID%
		minecraftDirectory := GetMinecraftDirectory(PID)
		instanceNumber := GetInstanceNumber(minecraftDirectory)
		if (!instanceNumber) {
            SendLog("instanceNumber.txt not found for PID = {1} and windowID = {2}", PID, windowID)
			ExitApp
		}
		else if (PID == PIDs[instanceNumber] && windowID == windowIDs[instanceNumber]) {
            SendLog(Format("Instance {1} is already managed correctly with PID = {2} and windowID = {3}", instanceNumber, PID, windowID))
			continue
		}
		else {
			windowIDs[instanceNumber] := windowID
			PIDs[instanceNumber] := PID
            SendLog(Format("Found instance {1} with PID = {2} and windowID = {3}", instanceNumber, PID, windowID))
			if (instanceManagerPID := instanceManagerPIDs[instanceNumber]) {
                DetectHiddenWindows, On
				PostMessage, MSG_UPDATE_PID, PID,,, ahk_pid %instanceManagerPID%
                DetectHiddenWindows, Off
                SendLog(Format("Sent MSG_UPDATE_PID to instanceManagerPID {1}", instanceManagerPID))
			}
			else {
				Run, "%A_ScriptDir%\scripts\instance_manager.ahk" %instanceNumber% %windowID% %PID%,,, instanceManagerPID
                DetectHiddenWindows, On
                WinWait, ahk_pid %instanceManagerPID%
                DetectHiddenWindows, Off
                instanceManagerPIDs[instanceNumber] := instanceManagerPID
                SendLog(Format("Started new instance manager with PID {1}", instanceManagerPID))
			}
		}
	}
    totalInstances := PIDs.MaxIndex()
    SendLog(Format("Found {1} total instances", totalInstances))
	if (!disableTTS) {
		ComObjCreate("SAPI.SpVoice").Speak("Ready")
	}
}

LockInstance(instanceNumber) {
    SendLog(Format("Locking instance {1}", instanceNumber))
	if (instanceNumber > 0 && instanceNumber <= totalInstances) {
		instanceManagerPID := instanceManagerPIDs[instanceNumber]
        DetectHiddenWindows, On
		PostMessage, MSG_LOCK,,,, ahk_pid %instanceManagerPID%
        DetectHiddenWindows, Off
        SendLog(Format("Sent MSG_LOCK to instance {1} with instanceManagerPID {2}", instanceNumber, instanceManagerPID))
	}
}

PlayInstance(instanceNumber) {
    SendLog(Format("Playing instance {1}", instanceNumber))
    if (instanceNumber > 0 && instanceNumber <= totalInstances) {
        instanceManagerPID := instanceManagerPIDs[instanceNumber]
        DetectHiddenWindows, On
        PostMessage, MSG_PLAY,,,, ahk_pid %instanceManagerPID%
        DetectHiddenWindows, Off
        SendLog(Format("Sent MSG_PLAY to instance {1} with instanceManagerPID {2}", instanceNumber, instanceManagerPID))
    }
}

ResetInstance(instanceNumber, ignoreLock) {
    SendLog(Format("Resetting instance {1} with ignoreLock = {2}", instanceNumber, ignoreLock))
	if (instanceNumber > 0 && instanceNumber <= totalInstances) {
		instanceManagerPID := instanceManagerPIDs[instanceNumber]
        DetectHiddenWindows, On
		PostMessage, MSG_RESET, ignoreLock,,, ahk_pid %instanceManagerPID%
        DetectHiddenWindows, Off
        SendLog(Format("Sent MSG_RESET with ignoreLock = {1} to instance {2} with instanceManagerPID {3}", ignoreLock, instanceNumber, instanceManagerPID))
	}
}

ResetAll() {
    SendLog("Resetting all instances")
	Loop, %totalInstances% {
		ResetInstance(A_Index, False)
	}
}

FocusReset(focusInstance) {
    SendLog(Format("Focus resetting with focusInstance = {1}", focusInstance))
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

SendLog(message) {
    if (logging) {
        FileAppend, [%A_TickCount%] [%A_YYYY-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%] [WALL_MAIN] %message%`n, %A_ScriptDir%\log.txt
    }
}

#Persistent
OnExit("HandleExit")

HandleExit(ExitReason) {
    SendLog("Exiting")
    if ExitReason not in Logoff,Shutdown
    {
        DetectHiddenWindows, On
        totalInstanceManagers := instanceManagerPIDs.MaxIndex()
        Loop, %totalInstanceManagers% {
            instanceManagerPID := instanceManagerPIDs[A_Index]
            WinClose, ahk_pid %instanceManagerPID%
            SendLog(Format("Closed instance manager for instance {1} with PID {2}", A_Index, instanceManagerPID))
        }
        DetectHiddenWindows, Off
    }
}

#Include %A_ScriptDir%\hotkeys.ahk