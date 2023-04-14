; General settings
global version := "1.3.2" ; your minecraft version
global rows := 3 ; number of rows on the wall scene
global columns := 3 ; number of columns on the wall scene
global useAtumHotkey := True ; whether to send the atumHotkey or manually tab through the menu
global atumHotkey := "F6" ; your "Create New World" key as bound in controls
global logging := False ; please keep this on so I might be able to help you with issues

; Extra features
global disableTTS := False ; disables the "Ready" when running the macro
global borderless := True ; automatically makes your instances borderless
global wideResets := True ; stretches your instances when resetting for better visibility
global widthMultiplier := 2.5 ; how wide you want your instances to be
global resetSounds := False ; whether reset.wav plays whenever you reset
global lockSounds := False ; whether lock.wav plays whenever you lock an instance
global audioGUI := False ; gui to capture ahk audio
global loadingScreenColor := 0x2E2117 ; color of the top left pixel of the loading screen, only change if you're using a texture pack
global obsSceneControlType := "N" ; N = numpad hotkeys (up to 9 instances), F = function hotkeys f13-f24 (up to 12 instances), C = custom key array (too many instances)
global obsWallSceneKey := "F12" ; hotkey to switch to your wall scene
global obsCustomKeyArray := [] ; add keys in quotes separated by commas, the index in the array corresponds to the scene

; Extra inputs
global switchToEasy := False ; switches difficulty to easy when you play a world (only used for 1.8+, older versions don't default back to normal)
global unpauseOnJoin := True ; presses ESC when you play a world

; Delays
global beforePauseDelay := 300 ; increase if you get too many void spawns / pausing is inconsistent
global resetDownDelay := 1000 ; how long the atumHotkey is held down for
global focusResetDelay := 300 ; time between switching to an instance and resetting all the other ones
global settingsDelay := 50 ; delay between tabbing to a button and pressing it
global guiDelay := 200 ; delay between changing GUIs and sending input
global pixelCheckDelay := 100 ; saves on performance, slightly more variation before instance is paused (not used for 1.3)
global worldLoadDelay := 1000 ; minimum amount of time between loading screen and world join (not used for 1.3)
global titleScreenFlashDelay := 500 ; maximum amount of time the title screen will flash for before joining a world (not used for 1.3)
global stateOutReadDelay := 100 ; how regularly wpstateout.txt is read (only used for 1.3)
global obsDelay := 100 ; increase if not changing scenes in OBS

; Affinity
global affinity := True ; manages the number of threads dedicated to your instances for better performance
; Thread count dedicated to... (-1 for calculated defaults)
global playThreadsOverride := -1 ; the instance you are playing
global resettingThreadsOverride := -1 ; resetting instances while you are on wall
global resettingBackgroundThreadsOverride := -1 ; resetting instances in the background
global idleThreadsOverride := -1 ; idle instances while you are on wall
global idleBackgroundThreadsOverride := -1 ; idle instances in the background
global lockedThreadsOverride := -1 ; locked instances while you are on wall
global lockedBackgroundThreadsOverride := -1 ; locked instances in the background