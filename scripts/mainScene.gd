extends Node
@export var gameScene: PackedScene

func _ready():
	get_viewport().set_embedding_subwindows(false) #important

	var game = gameScene.instantiate()
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
	add_child(window2)

	var container = SubViewportContainer.new()
	window2.add_child(container)

	#temporary for prototype
	var sv = SubViewport.new()
	sv.size = Vector2(1152, 648)
	sv.world_3d = get_viewport().world_3d
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var hud = CanvasLayer.new()
	hud.name = "HUD"
	sv.add_child(hud)

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
	#end of temporary
	
	
	container.add_child(sv)

	var cam2 = game.get_node("Player2/Camera3D")
	var cam_global = cam2.global_transform
	cam2.get_parent().remove_child(cam2) #removing camera from player node, kinda inefficient but works
	sv.add_child(cam2)
	cam2.global_transform = cam_global
	cam2.current = true
