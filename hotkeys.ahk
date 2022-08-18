#IfWinActive, Minecraft
    *U:: ResetInstance(GetActiveInstanceNumber(), True) ; reset while playing

#IfWinActive, Fullscreen Projector
	*E::ResetInstance(MousePosToInstanceNumber(), True) ; reset an instance on wall
	*R::PlayInstance(MousePosToInstanceNumber()) ; play an instance
	*F::FocusReset(MousePosToInstanceNumber()) ; play one instance, reset the others
	*T::ResetAll() ; reset all instances
	+LButton::LockInstance(MousePosToInstanceNumber()) ; lock an instance

	; reset keys (1-9)
	*1::ResetInstance(1, True)
	*2::ResetInstance(2, True)
    *3::ResetInstance(3, True)
    *4::ResetInstance(4, True)
    *5::ResetInstance(5, True)
    *6::ResetInstance(6, True)
    *7::ResetInstance(7, True)
    *8::ResetInstance(8, True)
    *9::ResetInstance(9, True)

    ; play instance keys (shift + 1-9)
    *+1::PlayInstance(1)
    *+2::PlayInstance(2)
    *+3::PlayInstance(3)
    *+4::PlayInstance(4)
    *+5::PlayInstance(5)
    *+6::PlayInstance(6)
    *+7::PlayInstance(7)
    *+8::PlayInstance(8)
	*+9::PlayInstance(9)