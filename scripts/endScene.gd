extends CanvasLayer

class_name EndScene

@onready var winner_label: Label = $VBoxContainer/WinnerLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var main_scene: Node = get_tree().root.get_child(0)  # Get mainScene

var controller_id: int = -1
var buttonaPressed: bool = false

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)

func _process(delta):
	var connected = Input.get_connected_joypads()
	if connected.size() == 0:
		return

	controller_id = connected[0] 
	var a_pressed = Input.is_joy_button_pressed(controller_id, JOY_BUTTON_A)

	if a_pressed and not buttonaPressed:
		buttonaPressed = true
		restart_button.emit_signal("pressed")
	elif not a_pressed:
		buttonaPressed = false

func displayWinner(winner_name: String) -> void:
	winner_label.text = "Game Over! " + winner_name + " wins!"

func _on_restart_pressed():
	# Call handleRestart in mainScene
	main_scene.handleRestart()
