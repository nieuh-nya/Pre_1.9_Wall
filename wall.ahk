#NoEnv
#SingleInstance, Force
#Include %A_ScriptDir%\scripts\utils.ahk
#Include %A_ScriptDir%\settings.ahk

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

if(SubStr(A_AhkVersion, 1, 3) != "1.1") {
	SendLog(Format("Wrong AHK version ({1}) detected, exiting", A_AhkVersion))
	MsgBox, Wrong AHK version, delete your current version and download 1.1
	ExitApp
}

global MSG_RESET := 0x1001
global MSG_LOCK := 0x1002
global MSG_PLAY := 0x1003
global MSG_CHANGED_ACTIVE_INSTANCE := 0x1004
global MSG_STARTED_PLAYING := 0x1005
global MSG_STOPPED_PLAYING := 0x1006

OnMessage(MSG_STARTED_PLAYING, "HandleStartedPlaying")
OnMessage(MSG_STOPPED_PLAYING, "HandleStoppedPlaying")

global instanceWidth := Floor(A_ScreenWidth / columns)
global instanceHeight := Floor(A_ScreenHeight / rows)
global totalInstances := 0
global activeInstanceNumber := 0

global PIDs := []
global instanceManagerPIDs := []

if (!FileExist("logs")) {
	FileCreateDir, logs
}
FileDelete, logs\log*.log

if (audioGUI) {
	Gui, New
	Gui, Show,, Wall Audio
}

SendLog("Setting up instances")

Send, {%obsWallSceneKey% down}
Sleep, %obsDelay%
Send, {%obsWallSceneKey% up}

titleFormat := "Minecraft"
if (SubStr(version, 1, 3) != "1.3") {
	titleFormat := titleFormat . " " . version
}
thisPID := DllCall("GetCurrentProcessId")
WinGet, allInstances, list, %titleFormat%
Loop, %allInstances% {
	windowID := allInstances%A_Index%
	WinGet, exe, ProcessName, ahk_id %windowID%
	SendLog(Format("Found window with ahk_exe = {1}", exe))
	if (exe != "javaw.exe") {
		continue
	}
	WinGet, PID, PID, ahk_id %windowID%
	minecraftDirectory := GetMinecraftDirectory(PID)
	SendLog(Format("minecraftDirectory = {1}", minecraftDirectory))
	instanceNumber := GetInstanceNumber(minecraftDirectory)
	if (!instanceNumber) {
		SendLog(Format("instanceNumber.txt not found for PID = {1} and windowID = {2}", PID, windowID))
		ExitApp
	}
	else {
		PIDs[instanceNumber] := PID
		SendLog(Format("Found instance {1} with PID = {2} and windowID = {3}", instanceNumber, PID, windowID))
		Run, "%A_ScriptDir%\scripts\instance_manager.ahk" %instanceNumber% %windowID% %PID% %thisPID%,,, instanceManagerPID
		DetectHiddenWindows, On
		WinWait, ahk_pid %instanceManagerPID%
		DetectHiddenWindows, Off
		instanceManagerPIDs[instanceNumber] := instanceManagerPID
		SendLog(Format("Started new instance manager with PID {1}", instanceManagerPID))
	}
}
totalInstances := PIDs.MaxIndex()
SendLog(Format("Found {1} total instances", totalInstances))

if (!disableTTS) {
	ComObjCreate("SAPI.SpVoice").Speak("Ready")
}

LockInstance(instanceNumber) {
	SendLog(Format("Locking instance {1}", instanceNumber))
	if (instanceNumber > 0 && instanceNumber <= totalInstances) {
		instanceManagerPID := instanceManagerPIDs[instanceNumber]
		SendLog(Format("Sending MSG_LOCK to {1}", instanceManagerPID))
		DetectHiddenWindows, On
		PostMessage, MSG_LOCK,,,, ahk_pid %instanceManagerPID%
		DetectHiddenWindows, Off
	}
}

PlayInstance(instanceNumber) {
	SendLog(Format("Playing instance {1}", instanceNumber))
	if (instanceNumber > 0 && instanceNumber <= totalInstances) {
		instanceManagerPID := instanceManagerPIDs[instanceNumber]
		SendLog(Format("Sending MSG_PLAY to {1}", instanceManagerPID))
		DetectHiddenWindows, On
		PostMessage, MSG_PLAY,,,, ahk_pid %instanceManagerPID%
		DetectHiddenWindows, Off
	}
}

ResetInstance(instanceNumber, ignoreLock) {
	if (instanceNumber == 0) {
		instanceNumber := activeInstanceNumber
	}
	SendLog(Format("Resetting instance {1} with ignoreLock = {2}", instanceNumber, ignoreLock))
	if (instanceNumber > 0 && instanceNumber <= totalInstances) {
		instanceManagerPID := instanceManagerPIDs[instanceNumber]
		SendLog(Format("Sending MSG_RESET to {1}", instanceManagerPID))
		DetectHiddenWindows, On
		PostMessage, MSG_RESET, ignoreLock,,, ahk_pid %instanceManagerPID%
		DetectHiddenWindows, Off
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
		if (A_Index != focusInstance) {
			ResetInstance(A_Index, False)
		}
	}
}

HandleStartedPlaying(instanceNumber) {
	activeInstanceNumber := instanceNumber
	SendLog(Format("Sending MSG_CHANGED_ACTIVE_INSTANCE with instanceNumber = {1} to all instanceManagers", instanceNumber))
	DetectHiddenWindows, On
	For index, instanceManagerPID in instanceManagerPIDs {
		if (index != instanceNumber) {
			PostMessage, MSG_CHANGED_ACTIVE_INSTANCE, instanceNumber,,, ahk_pid %instanceManagerPID%
		}
	}
	DetectHiddenWindows, Off
}

HandleStoppedPlaying(instanceNumber) {
	activeInstanceNumber := 0
	SendLog("Sending MSG_CHANGED_ACTIVE_INSTANCE with instanceNumber = 0 to all instanceManagers")
	DetectHiddenWindows, On
	For index, instanceManagerPID in instanceManagerPIDs {
		if (index != instanceNumber) {
			PostMessage, MSG_CHANGED_ACTIVE_INSTANCE, 0,,, ahk_pid %instanceManagerPID%
		}
	}
	DetectHiddenWindows, Off
}

MousePosToInstanceNumber() {
	MouseGetPos, mouseX, mouseY
	return (Floor(mouseY / instanceHeight) * columns) + Floor(mouseX / instanceWidth) + 1
}

SendLog(message) {
	if (logging) {
		FileAppend, [%A_TickCount%] [%A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%] %message%`n, %A_ScriptDir%\logs\log.log
	}
}

#Persistent
OnExit("HandleExit")

HandleExit(ExitReason) {
	SendLog("Exiting")
	if ExitReason not in Logoff,Shutdown ; HOLY SHIT PLEASE LET ME PUT THE BRACKET HERE I AM GOING TO CRY
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