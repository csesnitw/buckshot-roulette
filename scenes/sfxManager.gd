extends AudioStreamPlayer

var shootSfx = preload("res://assets/sfx/shoot_awp.mp3")
var blankSfx = preload("res://assets/sfx/blank_shot.mp3")

func playShoot():
	stop()
	stream = shootSfx
	play()

func playBlank():
	stop()
	stream = blankSfx
	play()

# easily extend sfx by adding more shit here....
