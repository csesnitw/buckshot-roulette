extends CanvasLayer

class_name EndScene

@onready var winner_label: Label = $VBoxContainer/WinnerLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var main_scene: Node = get_tree().root.get_child(0)  # Get mainScene

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)

func displayWinner(winner_name: String) -> void:
	winner_label.text = "Game Over! " + winner_name + " wins!"

func _on_restart_pressed():
	# Call handleRestart in mainScene
	main_scene.handleRestart()
