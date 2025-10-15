extends Node

# setup in insepctor!
@export var gameScene2: PackedScene
@export var gameScene3: PackedScene
@export var gameScene4: PackedScene

@onready var home_screen = $HomeScreen
@onready var two_player_button = $HomeScreen/VBoxContainer/ButtonContainer/TwoPlayer
@onready var threePlayerButton = $HomeScreen/VBoxContainer/ButtonContainer/ThreePlayer
@onready var fourPlayerButton = $HomeScreen/VBoxContainer/ButtonContainer/FourPlayer

func _ready():
	two_player_button.pressed.connect(func(): setupPlayers(gameScene2, 2))
	threePlayerButton.pressed.connect(func(): setupPlayers(gameScene3, 3))
	fourPlayerButton.pressed.connect(func(): setupPlayers(gameScene4, 4))


func createWindow(game, playerName: String, title: String):
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
	container.add_child(sv)

	var player = game.get_node(playerName)
	player.target_label = sv.get_node("HUD/TargetLabel")

	var cam = game.get_node(playerName + "/Camera3D")
	var cam_global = cam.global_transform
	cam.get_parent().remove_child(cam)
	sv.add_child(cam)
	cam.global_transform = cam_global
	cam.current = true

func setupPlayers(scene: PackedScene, playerCount: int):
	home_screen.visible = false
	get_viewport().set_embedding_subwindows(false)
	
	var game = scene.instantiate()
	add_child(game)
	
	game.get_node("Player1/Camera3D").current = true
	get_window().title = "Player 1"

	for i in range(2, playerCount + 1):
		var playerName = "Player" + str(i)
		var title = "Player " + str(i)
		createWindow(game, playerName, title)
