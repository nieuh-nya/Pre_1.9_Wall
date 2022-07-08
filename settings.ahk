; General settings
global rows := 3 ; number of row on the wall scene
global cols := 3 ; number of columns on the wall scene

; Extra features
global disableTTS := False
global borderless := True ; automatically makes your instances borderless
global wideResets := True
global widthMultiplier := 2.5
global resetSounds := True
global lockSounds := True
global countAttempts := True

; Settings reset, Set to 0 or False if you dont want to reset settings
global renderDistance := 5 ; default RD you want to reset on
global switchToEasy := True
global renderDistanceOnJoin := 16 ; renderDistance also needs to be enabled
global unpauseOnJoin := True
global fastFocusReset := False ; try it out, less consistent if it changes settings on world join
global coop := False ; automatically opens to LAN

; Delays
global beforePauseDelay := 300 ; increase if you get too many void spawns
global obsDelay := 100 ; increase if not changing scenes in OBS
global settingsDelay := 75 ; how long to wait between Tab-ing to an option and sending input to it
global guiDelay := 400 ; how long to wait after changing menus