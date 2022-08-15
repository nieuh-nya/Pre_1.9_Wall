#IfWinActive, Minecraft
    *U:: ExitWorld() ; reset while playing

#IfWinActive, Fullscreen Projector
	*E::ResetInstance(MousePosToInstNumber()) ; reset an instance on wall
	*R::PlayInstance(MousePosToInstNumber()) ; play an instance
	*F::FocusReset(MousePosToInstNumber()) ; play one instance, reset the others
	*T::ResetAll() ; reset all instances
	+LButton::LockInstance(MousePosToInstNumber()) ; lock an instance

	; Reset keys (1-9)
	*1::ResetInstance(1)
	*2::ResetInstance(2)
    *3::ResetInstance(3)
    *4::ResetInstance(4)
    *5::ResetInstance(5)
    *6::ResetInstance(6)
    *7::ResetInstance(7)
    *8::ResetInstance(8)
    *9::ResetInstance(9)

    ; Switch to instance keys (Shift + 1-9)
    *+1::SwitchInstance(1)
    *+2::SwitchInstance(2)
    *+3::SwitchInstance(3)
    *+4::SwitchInstance(4)
    *+5::SwitchInstance(5)
    *+6::SwitchInstance(6)
    *+7::SwitchInstance(7)
    *+8::SwitchInstance(8)
	*+9::SwitchInstance(9)