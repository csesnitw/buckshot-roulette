extends Node

# setup in insepctor!
@export var gameScene2: PackedScene
@export var gameScene3: PackedScene
@export var gameScene4: PackedScene
@export var endScene: PackedScene

@onready var home_screen = $HomeScreen
@onready var two_player_button = $HomeScreen/VBoxContainer/ButtonContainer/TwoPlayer
@onready var threePlayerButton = $HomeScreen/VBoxContainer/ButtonContainer/ThreePlayer
@onready var fourPlayerButton = $HomeScreen/VBoxContainer/ButtonContainer/FourPlayer

# Track instances for cleanup
var current_game_instance: Node = null
var player_windows: Array[Window] = []
var num_players: int = 0
var gameManRef

func _ready():
	two_player_button.pressed.connect(func(): setupPlayers(gameScene2, 2))
	threePlayerButton.pressed.connect(func(): setupPlayers(gameScene3, 3))
	fourPlayerButton.pressed.connect(func(): setupPlayers(gameScene4, 4))


func createWindow(game, playerName: String, title: String) -> Window:
	var window = Window.new()
	window.size = Vector2(960, 480) #1/4th of 1080p (minus taskbar ish) dw ts is temp and assign this and sv size for arcade machine
	window.position = Vector2(860, 340) #arbitrary window pos from prev commit (modify for arcade machine)
	window.visible = true
	window.title = title
	add_child(window)

	var container = SubViewportContainer.new()
	window.add_child(container)

	var sv = SubViewport.new()
	sv.size = Vector2(960, 480) # probably should make this a var
	sv.world_3d = get_viewport().world_3d
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# TODO: revamp this
	###
	var hud = CanvasLayer.new()
	hud.name = "HUD"

	var label = Label.new()
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	label.name = "TargetLabel"
	label.anchor_left = 0
	label.anchor_top = 1
	label.anchor_right = 0
	label.anchor_bottom = 1
	label.position = Vector2(10, -30)
	hud.add_child(label)

	sv.add_child(hud)
	###

	container.add_child(sv)

	var player = game.get_node(playerName)
	###
	player.target_label = sv.get_node("HUD/TargetLabel")
	###

	var cam = game.get_node(playerName + "/RotPivot/Camera3D")
	var cam_global = cam.global_transform
	cam.get_parent().remove_child(cam)
	gameManRef.fuckedUpPlayerToViewportMap[player] = cam
	sv.add_child(cam)
	cam.global_transform = cam_global
	cam.current = true

	return window

func setupPlayers(scene: PackedScene, playerCount: int):
	# Hide home screen
	home_screen.visible = false

	# Set up the game windows
	get_viewport().set_embedding_subwindows(false)

	# Store the number of players
	num_players = playerCount
	var game = scene.instantiate()
	gameManRef = game.get_node("GameManager")
	#print(gameManRef)
	# DO NOT TOUCH ALSO ENSURE ROTPIVOT AND CAMERA HAVE SAME TRANSFORM
	for i in range(playerCount):
		gameManRef.fuckedUpPlayerToViewportMap[game.get_node("Player" + str(i))] = game.get_node("Player" + str(i) + "/RotPivot/Camera3D")
	
	
	# AFTET THIS POINT SHIT STOPS WORKING LITERALLY GHOST CODE
	current_game_instance = game  # Store reference
	add_child(game)

	# Set player 1 view
	game.get_node("Player1/RotPivot/Camera3D").current = true
	get_window().title = "Player 1"
	print("hello")
	

	# Create windows for players 2, 3, 4
	for i in range(2, playerCount + 1):
		var playerName = "Player" + str(i)
		var title = "Player " + str(i)
		player_windows.append(createWindow(game, playerName, title))

# Called by gameManager when game ends
func handleEndGame(winner_name: String):
	# Hide all player UI labels
	#if current_game_instance:
		#var player1 = current_game_instance.get_node_or_null("Player1")
		#var player2 = current_game_instance.get_node_or_null("Player2")
		#
		#if player1:
			#player1.target_label.visible = false
			#player1.get_node("CanvasLayer").visible = false
		#if player2:
 			#player2.target_label.visible = false
			#player2.get_node("CanvasLayer").visible = false

	# Close all the additional windows immediately
	for player_window in player_windows:
		if player_window:
			player_window.queue_free()

	player_windows.clear()

	# Instantiate and display end scene
	var end_scene_instance = endScene.instantiate()
	add_child(end_scene_instance)

	# Pass winner name to end scene
	end_scene_instance.displayWinner(winner_name)

# Called by endScene when restart button is pressed
func handleRestart():
	# Remove the current game instance
	if current_game_instance:
		current_game_instance.queue_free()
		current_game_instance = null

	# Remove all end scenes
	for child in get_children():
		if child is EndScene:
			child.queue_free()

	# Show home screen again
	home_screen.visible = true
	get_window().title = "Buckshot Roulette"  # Reset main window title

	# Reset viewport embedding for next game
	get_viewport().set_embedding_subwindows(true)
