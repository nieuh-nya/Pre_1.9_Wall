; General settings
global version := "1.8.9" ; your minecraft version
global rows := 3 ; number of row on the wall scene
global cols := 3 ; number of columns on the wall scene
global lowBitmaskMultiplier := 0.75

; Extra features
global disableTTS := False ; disables the "Ready" when running the macro
global affinity := True
global borderless := True ; automatically makes your instances borderless
global wideResets := True ; stretches your instances when resetting for better visibility
global widthMultiplier := 2.5 ; how wide you want your instances to be
global resetSounds := True ; whether reset.wav plays whenever you reset
global lockSounds := True ; whether lock.wav plays whenever you lock an instance
global countAttempts := True ; counts your total and daily attempts
global loadingScreenColor := 0x2E2117 ; color of the top left pixel of the loading screen, only change if you're using a texture pack

; Extra inputs
global switchToEasy := False ; switches difficulty to easy when you play a world
global unpauseOnJoin := True ; presses ESC when you play a world
global coop := False ; automatically opens to LAN

; Delays
global beforePauseDelay := 300 ; increase if you get too many void spawns
global obsDelay := 100 ; increase if not changing scenes in OBS
global settingsDelay := 75 ; how long to wait between Tab-ing to an option and sending input to it
global guiDelay := 300 ; how long to wait after changing menus