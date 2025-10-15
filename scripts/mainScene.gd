extends Node

@export var gameScene: PackedScene
@export var endScene: PackedScene

@onready var home_screen = $HomeScreen
@onready var two_player_button = $HomeScreen/VBoxContainer/ButtonContainer/TwoPlayer

var current_game_instance: Node = null
var player2_window: Window = null  # TODO: Need to add player3_window and player4_window once its implemented

func _ready():
	# Connect the 2-player button
	two_player_button.pressed.connect(_on_two_player_pressed)

func _on_two_player_pressed():
	# Hide home screen
	home_screen.visible = false
	
	# Set up the game windows
	get_viewport().set_embedding_subwindows(false)
	
	var game = gameScene.instantiate()
	current_game_instance = game  # Store reference
	add_child(game)
	
	# Player 1
	game.get_node("Player1/Camera3D").current = true
	get_window().title = "Player 1"

	# Player 2
	var window2 = Window.new()
	window2.size = Vector2(1152, 648)
	window2.position = Vector2(860, 340)
	window2.visible = true
	window2.title = "Player 2"
	player2_window = window2
	add_child(window2)

	var container = SubViewportContainer.new()
	window2.add_child(container)

	var sv = SubViewport.new()
	sv.size = Vector2(1152, 648)
	sv.world_3d = get_viewport().world_3d
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var hud = CanvasLayer.new()
	hud.name = "HUD"

	# TODO: Should revamp/remove this
	var label = Label.new()
	label.add_theme_color_override("font_color", Color(0,0,0))
	label.name = "TargetLabel"
	label.anchor_left = 0
	label.anchor_top = 1
	label.anchor_right = 0
	label.anchor_bottom = 1
	label.position = Vector2(10, -30)
	hud.add_child(label)
	
	sv.add_child(hud)
	var player2 = game.get_node("Player2")
	player2.target_label = sv.get_node("HUD/TargetLabel")
	
	container.add_child(sv)

	var cam2 = game.get_node("Player2/Camera3D")
	var cam_global = cam2.global_transform
	cam2.get_parent().remove_child(cam2)
	sv.add_child(cam2)
	cam2.global_transform = cam_global
	cam2.current = true

# Called by gameManager when game ends
func handleEndGame(winner_name: String) -> void:
	# Hide all player UI labels
	if current_game_instance:
		var player1 = current_game_instance.get_node_or_null("Player1")
		var player2 = current_game_instance.get_node_or_null("Player2")
		
		# TODO: Either create a list and loop through them or manually add player3 and player4
		if player1:
			player1.get_node("CanvasLayer").visible = false
		if player2:
			player2.get_node("CanvasLayer").visible = false
	
	# Close the extra windows
	# TODO: Should add player 3 and player 4
	if player2_window:
		player2_window.queue_free()
		player2_window = null
	
	# Instantiate and display end scene
	var end_scene_instance = endScene.instantiate()
	add_child(end_scene_instance)
	
	# Pass winner name to end scene
	end_scene_instance.displayWinner(winner_name)

# Called by endScene when restart button is pressed
func handleRestart() -> void:
	# Remove the current game instance
	if current_game_instance:
		current_game_instance.queue_free()
		current_game_instance = null
	
	# Remove all end scenes
	for child in get_children():
		if child is EndScene:
			child.queue_free()
	
	# Remove all Window instances (Player 2 window)
	for child in get_children():
		if child is Window:
			child.queue_free()
	
	# Show home screen again
	home_screen.visible = true
	get_window().title = "Buckshot Roulette"  # Reset main window title
	
	# Reset viewport embedding for next game
	get_viewport().set_embedding_subwindows(true)
