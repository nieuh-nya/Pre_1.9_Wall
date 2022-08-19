; General settings
global version := "1.8.9" ; your minecraft version
global rows := 3 ; number of row on the wall scene
global columns := 3 ; number of columns on the wall scene

; Extra features
global disableTTS := False ; disables the "Ready" when running the macro
global borderless := True ; automatically makes your instances borderless
global wideResets := True ; stretches your instances when resetting for better visibility
global widthMultiplier := 2.5 ; how wide you want your instances to be
global resetSounds := True ; whether reset.wav plays whenever you reset
global lockSounds := True ; whether lock.wav plays whenever you lock an instance
global countAttempts := True ; counts your total and daily attempts
global loadingScreenColor := 0x2E2117 ; color of the top left pixel of the loading screen, only change if you're using a texture pack
global obsSceneControlType := "N" ; N = numpad hotkeys (up to 9 instances), F = function hotkeys f13-f24 (up to 12 instances), C = custom key array (too many instances)
global obsWallSceneKey := "F12" ; hotkey to switch to your wall scene
global obsCustomKeyArray := [] ; add keys in quotes separated by commas, the index in the array corresponds to the scene

; Extra inputs
global switchToEasy := False ; switches difficulty to easy when you play a world
global unpauseOnJoin := True ; presses ESC when you play a world
global coop := False ; automatically opens to LAN

; Delays
global beforePauseDelay := 300 ; increase if you get too many void spawns
global obsDelay := 100 ; increase if not changing scenes in OBS
global settingsDelay := 50 ; how long to wait between Tab-ing to an option and sending input to it
global guiDelay := 300 ; how long to wait after changing menus
global pixelCheckDelay := 100 ; how long to wait between each pixel check
global worldLoadDelay := 1000 ; minimum amount of time between loading screen and world join
global titleScreenFlashDelay := 500 ; maximum amount of time the title screen will flash for before joining a world
global focusResetDelay := 300 ; time between switching to an instance and resetting all the other ones

; Affinity
global affinity := True ; manages the number of threads dedicated to your instances for better performance
global affinityCheckDelay := 100 ; how regularly an instance's state is checked to update affinity
; Thread count dedicated to...
global playThreadsOverride := -1 ; the instance you are playing
global highThreadsOverride := -1 ; resetting instances while you are on wall
global lockThreadsOverride := -1 ; locked instances while you are on wall
global lowThreadsOverride := -1 ; idle instances while you are on wall and resetting background instances while you are playing
global superLowThreadsOverride := -1 ; idle background instances while you are playing