#NoEnv

GetMinecraftDirectory(PID) {
	command := Format("powershell.exe $x = Get-WmiObject Win32_Process -Filter \""ProcessId = {1}\""; $x.CommandLine", PID)
	rawOut := RunHide(command)
	if (InStr(rawOut, "--gameDir")) {
		strStart := RegExMatch(rawOut, "P)--gameDir (?:""(.+?)""|([^\s]+))", strLen, 1)
		return SubStr(rawOut, strStart+10, strLen-10) . "\"
	} 
	else {
		strStart := RegExMatch(rawOut, "P)(?:-Djava\.library\.path=(.+?) )|(?:\""-Djava\.library.path=(.+?)\"")", strLen, 1)
		if (SubStr(rawOut, strStart+20, 1) == "=") {
		strLen -= 1
		strStart += 1
		}
		return StrReplace(SubStr(rawOut, strStart+20, strLen-28) . ".minecraft\", "/", "\")
	}
}

GetInstanceNumber(minecraftDirectory) {
	instanceNumberFile := minecraftDirectory . "instanceNumber.txt"
	instanceNumber := -1
	if (!FileExist(instanceNumberFile)) {
		MsgBox, Missing instanceNumber.txt in %minecraftDirectory%
	}
	else {
		FileRead, instanceNumber, %instanceNumberFile%
	}
	return instanceNumber
}

GetActiveInstanceNumber() {
    FileRead, activeInstanceNumber, activeInstance.txt
    if (ErrorLevel) {
        return 0
    }
    return activeInstanceNumber
}

MakeWindowWide(windowID, widthMultiplier) {
	newHeight := Floor(A_ScreenHeight / widthMultiplier)
	WinRestore, ahk_id %windowID%
	WinMove, ahk_id %windowID%,, 0, 0, %A_ScreenWidth%, %newHeight%
}

GetTopLeftPixelColor(windowID) {
	return PixelColorSimple(0, 0, windowID)
}

PixelColorSimple(pc_x, pc_y, pc_wID) {
	if (pc_wID) {
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

GetBitMask(threadCount) {
    return (2 ** threadCount) - 1
}

RunHide(command) {
	dhw := A_DetectHiddenWindows
	DetectHiddenWindows, On
	Run, %ComSpec%,, Hide, cPid
	WinWait, ahk_pid %cPid%
	DetectHiddenWindows, %dhw%
	DllCall("AttachConsole", "uint", cPid)

	shell := ComObjCreate("WScript.Shell")
	exec := shell.Exec(command)
	result := exec.StdOut.ReadAll()

	DllCall("FreeConsole")
	Process, Close, %cPid%
	return result
}
