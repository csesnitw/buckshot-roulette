extends Node3D

class_name Player

signal target_changed(target_node)
signal damage_animation_finished

# Player properties
var hp: int
var inventory: Array = []
var power: int = 1
var hasDoubleDamage: bool = false
var current_target_index: int = 0
var targets: Array = []
var duplicateTargets: Array = []
var is_my_turn: bool = false
var game_state
var selectingTarget: bool = false
var pendingUpgrade: Upgrade = null
var upgrade_in_use: Upgrade = null
var is_playing_animation: bool = true
var taking_damage_animation_playing: bool = false
var controllerID: int = -1
var stickReset: bool = true
var inventoryOverlay: Node = null
var button_x = false

#@onready var target_label: Label = $CanvasLayer/TargetLabel
@onready var game_manager: Node = get_node("../GameManager")
@onready var gun: Node3D = $RotPivot/GunAndCameraPivot/Gun
@onready var health_jug = $HealthJug
@onready var blob_animation_player = $RotPivot/blob/AnimationPlayer
@onready var juice_animation_player = $JuiceAnimationPlayer
@onready var mag_glass_model = $Sketchfab_Scene
@onready var small_gun_model = $Gun
@onready var pill = $Pill
@onready var pooly = $pool_floatie

func _init(_name: String = "Player", _hp: int = 3):
	name = _name
	
	inventory = []

func _ready():
	hp = game_manager.maxHP
	#target_label.visible = false
	health_jug.create(game_manager.maxHP-1)
	blob_animation_player.play("idle")
	blob_animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))
	if self.name == "Player1": #player1's camera is not mapped in viewport logic
		game_manager.fuckedUpPlayerToViewportMap[self] = self.get_node("RotPivot/GunAndCameraPivot/Camera3D")

	
func _on_animation_finished(anim_name):
	if anim_name == "getting_shot":
		if hp != 0:
			blob_animation_player.play("idle")
		else:
			var blob_node = get_node_or_null("RotPivot/blob")
			if blob_node:
				blob_node.hide()
	
func _process(delta):
	$RotPivot/blob.rotation.y = $RotPivot/GunAndCameraPivot.rotation.y + PI
	if game_state.isUpgradeRound:
		gun.visible = false
	if not is_my_turn:
		gun.visible = false
		return
	

	var left_pressed = Input.is_action_just_pressed("left_arrow")
	var right_pressed = Input.is_action_just_pressed("right_arrow")
	var select_pressed = Input.is_action_just_pressed("spacebar")

	if controllerID >= 0:
		var axis_x = Input.get_joy_axis(controllerID, JOY_AXIS_LEFT_X)
		var aPressed = Input.is_joy_button_pressed(controllerID, JOY_BUTTON_A)

		if abs(axis_x) < 0.3:
			stickReset = true
		else:
			if stickReset:
				if axis_x < -0.5:
					left_pressed = true
					stickReset = false
				elif axis_x > 0.5:
					right_pressed = true
					stickReset = false

		if aPressed and not button_x:
			select_pressed = true
			button_x = true
		elif not aPressed:
			button_x = false

	if left_pressed:
		var init_target_index = current_target_index
		current_target_index = (current_target_index - 1 + targets.size()) % targets.size()
		update_target()

	elif right_pressed:
		var init_target_index = current_target_index
		current_target_index = (current_target_index + 1) % targets.size()
		update_target()

	elif select_pressed:
		if targets.size() == 0:
			return
		var target = targets[current_target_index]
		if selectingTarget:
			selectingTarget = false
			game_manager.useUpgrade(pendingUpgrade, self, target)
			pendingUpgrade = null
			targets = duplicateTargets.duplicate()
			return
		if game_state.isUpgradeRound:
			if target is Upgrade:
				is_my_turn = false
				call_deferred("pickUpgradeDeferred", target)
		else:
			if target is Player:
				is_my_turn = false
				call_deferred("shootDeferred", target)
			elif target is Upgrade:
				call_deferred("useUpgradeDeferred", target)

func pickUpgradeDeferred(target: Upgrade):
	game_manager.pickUpUpgrade(self, target)

func shootDeferred(target: Player):
	game_manager.shootPlayer(self, target)

func useUpgradeDeferred(target: Upgrade, targetPlayerRef: Player = self):
	if target.upgrade_type == Upgrade.UpgradeType.handcuff:
		selectingTarget = true;
		pendingUpgrade = target
		duplicateTargets = targets.duplicate()
		duplicateTargets.erase(target)
		targets = game_state.alivePlayers.duplicate()
		targets.erase(self)
		current_target_index = 0
		update_target()
		#target_label.visible = true
		return
	elif target.upgrade_type == Upgrade.UpgradeType.magGlass:
		play_mag_glass_animation()
	game_manager.useUpgrade(target, self, targetPlayerRef)

	if target.upgrade_type == Upgrade.UpgradeType.beer:
		upgrade_in_use = target
	else:
		targets.erase(target)
		if targets.size() > 0:
			current_target_index = (current_target_index + 1) % targets.size()
		else:
			current_target_index = 0
		update_target()
	
	
func update_target():
	if upgrade_in_use != null and upgrade_in_use.upgrade_type == Upgrade.UpgradeType.beer:
		return	
	#var inventory_icons: Array[String] = []
	#
	#for upgrade in inventory:
		#inventory_icons.append(getInventoryIcon(upgrade))
	
	if targets.size() > 0:
		var target = targets[current_target_index]
		target_changed.emit(target)
		if target is Player:
			#target_label.set_text("|".join(inventory_icons))
			inventoryOverlay.updateInventory(inventory, current_target_index - len(game_state.alivePlayers))
			
			if target == self:
				game_manager.self_target_animation(self)
			else:
				game_manager.update_target_animation(self, target.get_node("target_for_gun").global_transform.origin)
		elif target is Upgrade:
			#target_label.set_text("|".join(inventory_icons) + "\nChosen: " + getInventoryIcon(target))
			
			if game_state.isUpgradeRound:
				for target_temp in targets:
					if target_temp.is_selected:
						game_manager.rendered_animation_object[target_temp].get_node_or_null("AnimationPlayer").play_backwards("pop up")
					target_temp.is_selected = false
				target.is_selected = true
				game_manager.rendered_animation_object[target].get_node_or_null("AnimationPlayer").play("pop up")
				inventoryOverlay.updateInventory(inventory, -1)
				inventoryOverlay.setLabelText(inventoryOverlay.getInventoryIconAndName(target)["name"])
			else:
				inventoryOverlay.updateInventory(inventory, current_target_index - len(game_state.alivePlayers))
				game_manager.gun_rotate_animation(self, Vector3(0,10,0))

func onTurnEnd(new_game_state: GameState, current_player_index: int):
	game_state = new_game_state
	is_my_turn = (game_state.alivePlayers[current_player_index] == self)
	#target_label.visible = is_my_turn
	if !targets.is_empty():
		current_target_index = 0
		inventoryOverlay.updateInventory(inventory, current_target_index - len(game_state.alivePlayers))
	else: 
		print("Something gones wrong")
	
	if is_my_turn:
		if game_state.isUpgradeRound:
			targets = remove_nulls_from_array(game_state.upgradesOnTable)
			if targets.size() == 0:
				targets = remove_nulls_from_array(game_state.alivePlayers + inventory)
		else:
			targets = remove_nulls_from_array(game_state.alivePlayers + inventory)
		update_target()
	else:
		if self in game_state.handCuffedPlayers:
			blob_animation_player.play("handcuffed")
		else:
			if !is_playing_animation:
				blob_animation_player.play("idle")
	

# Inventory management
func addInventory(upgrade: Upgrade) -> void:
	inventory.append(upgrade)
	inventoryOverlay.updateInventory(inventory, current_target_index - len(game_state.alivePlayers))
	upgrade.reparent(self)
	upgrade.position = health_jug.position
	upgrade.position.z += 3
	var cam = Camera3D.new()
	upgrade.add_child(cam)
	cam.make_current()	

func removeInventory(upgrade: Upgrade) -> void:
	if upgrade in inventory:
		inventory.erase(upgrade)
		inventoryOverlay.updateInventory(inventory, current_target_index - len(game_state.alivePlayers))

func setInventoryOverlay(inventory_overlay):
	inventoryOverlay = inventory_overlay

# Check if player has a specific upgrade
func hasUpgrade(upgrade: Upgrade) -> bool:
	return upgrade in inventory

# Apply damage to the player
func takeDamage(amount: int) -> void:
	var damage_to_take = min(hp, amount)
	if damage_to_take <= 0:
		return
	hp -= damage_to_take
	
	play_damage_animation(damage_to_take)

func play_damage_animation(damage_taken: int) -> void:
	game_manager.animations_to_play_before_next_round_queue += damage_taken
	while taking_damage_animation_playing:
		await get_tree().process_frame
	taking_damage_animation_playing = true
	for i in range(damage_taken):
		taking_damage_animation_playing = true
		is_playing_animation = true
		blob_animation_player.play("RESET")
		blob_animation_player.play("getting_shot")

		if not health_jug.is_empty():
			juice_animation_player.play("drink")
			await get_tree().create_timer(1).timeout
			health_jug.drink()
			juice_animation_player.play_backwards("drink")
			await get_tree().create_timer(1).timeout

	taking_damage_animation_playing = false
	game_manager.animations_to_play_before_next_round_queue -= damage_taken
	emit_signal("damage_animation_finished")
	

# Heal the player
func heal(amount: int, max_hp: int) -> void:
	hp += amount
	if hp > max_hp:
		hp = max_hp
	for i in amount:
		health_jug.get_node("juice_carton").visible = true
		health_jug.get_node("AnimationPlayer").play("pour_juice")
		await get_tree().create_timer(health_jug.get_node("AnimationPlayer").get_animation("pour_juice").length).timeout
		health_jug.get_node("juice_carton").visible = false
		health_jug.refill()

# Optional: check if player is alive
func isAlive() -> bool:
	return hp > 0

func remove_nulls_from_array(original_array: Array) -> Array:
	var filtered_array = []
	for item in original_array:
		if item != null:
			filtered_array.append(item)
	return filtered_array
@onready var animationPlayer = $AnimationPlayer

func _on_juice_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "drink_coffee":
		get_node("cup_only_new").visible = false
		
		if upgrade_in_use:
			targets.erase(upgrade_in_use)
			upgrade_in_use = null
			if targets.size() > 0:
				current_target_index = (current_target_index + 1) % targets.size()
			else:
				current_target_index = 0
			update_target()

		# Once the coffee animation finishes, show the bullet type
		if game_manager and game_manager.shotgunShells.size() > 0:
			var bullet_type = game_manager.shotgunShells[0]
			var bullet_type_text = "BLANK EJECTED" if bullet_type == 0 else "LIVE EJECTED"

			var info_overlay = game_manager.ROUND_START_INFO_SCENE.instantiate()

			if name == "Player1":
				get_tree().root.add_child(info_overlay)
				info_overlay.show_bullet_type(bullet_type_text)
			else:
				var player_window = null
				for i in range(game_manager.players.size()):
					if game_manager.players[i] == self:
						if i - 1 < game_manager.windowRefs.size():
							player_window = game_manager.windowRefs[i - 1]
						break
				
				if player_window:
					var subviewport_container = player_window.get_child(0)
					var subviewport = subviewport_container.get_child(0)
					subviewport.add_child(info_overlay)
					await get_tree().process_frame
					info_overlay.show_bullet_type(bullet_type_text)

func play_mag_glass_animation():
	mag_glass_model.visible = true
	small_gun_model.visible = true
	gun.visible = false

	var tween = create_tween()
	
	# Fade in
	_set_models_alpha(mag_glass_model, 0.0)
	_set_models_alpha(small_gun_model, 0.0)
	tween.tween_method(Callable(self, "_set_models_alpha").bind(mag_glass_model), 0.0, 1.0, 0.5)
	tween.tween_method(Callable(self, "_set_models_alpha").bind(small_gun_model), 0.0, 1.0, 0.5)
	await tween.finished

	await get_tree().create_timer(3.0).timeout
	
	var fade_out_tween = create_tween()
	# Fade out
	fade_out_tween.tween_method(Callable(self, "_set_models_alpha").bind(mag_glass_model), 1.0, 0.0, 0.5)
	fade_out_tween.tween_method(Callable(self, "_set_models_alpha").bind(small_gun_model), 1.0, 0.0, 0.5)
	await fade_out_tween.finished

	mag_glass_model.visible = false
	small_gun_model.visible = false
	gun.visible = true # Make main gun visible again
func play_handsaw_animation():
	pill.visible = true
	gun.visible = false

	var tween = create_tween()
	var original_pos = pill.position
	var original_rot = pill.rotation_degrees

	var blob_node = $RotPivot/blob  # assuming this is the blob node
	var original_scale = blob_node.scale

	# Lift pill up
	tween.tween_property(pill, "position:y", original_pos.y + 0.4, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Tilt like sipping + scale blob up
	tween.tween_property(pill, "rotation_degrees:z", original_rot.z + 25, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(blob_node, "scale", original_scale * 1.3, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Pause
	tween.tween_interval(0.5)

	# Return to normal rotation/position + scale blob back
	tween.tween_property(pill, "rotation_degrees:z", original_rot.z, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pill, "position:y", original_pos.y, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(blob_node, "scale", original_scale, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished
	await get_tree().create_timer(0.3).timeout
	pill.visible = false
	gun.visible = true
func play_handcuff_animation():
	blob_animation_player.play("handcuffed")

	pooly.visible = true
	pooly.position.y = 15  

	var tween = create_tween()
	tween.tween_property(pooly, "position:y", 16, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(pooly, "position:y", 15, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

	# Wait until the player's turn is over (handcuffed duration)
	while is_my_turn:
		await get_tree().process_frame

	# Revert the floatie after the turn ends
	var revert_tween = create_tween()
	revert_tween.tween_property(pooly, "position:y", 40, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await revert_tween.finished
	pooly.visible = false
	# Return player animation to idle after turn ends
	if hp > 0:
		blob_animation_player.play("idle")

func _set_models_alpha(node: Node3D, alpha: float):
	for child in node.get_children():
		if child is MeshInstance3D:
			var material = child.get_active_material(0)
			if material:
				var new_material = material.duplicate()
				var albedo = new_material.albedo_color
				albedo.a = alpha
				new_material.albedo_color = albedo
				
				new_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
				child.set_surface_override_material(0, new_material)
				child.set_surface_override_material(0, new_material)
