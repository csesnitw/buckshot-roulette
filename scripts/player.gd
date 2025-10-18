extends Node3D

class_name Player

signal target_changed(target_node)

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
var is_playing_animation: bool = true

@onready var target_label: Label = $CanvasLayer/TargetLabel
@onready var game_manager: Node = get_node("../GameManager")
@onready var gun: Node3D = $RotPivot/GunAndCameraPivot/Gun
@onready var animation_player: AnimationPlayer = $RotPivot/GunAndCameraPivot/Gun/AnimationPlayer
@onready var health_jug = $HealthJug
@onready var blob_animation_player = $RotPivot/blob/AnimationPlayer
@onready var juice_animation_player = $JuiceAnimationPlayer

func _init(_name: String = "Player", _hp: int = 3):
	name = _name
	
	inventory = []

func _ready():
	hp = game_manager.maxHP
	target_label.visible = false
	health_jug.create(game_manager.maxHP)
	blob_animation_player.play("idle")
	blob_animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
func _on_animation_finished(anim_name):
	if anim_name == "getting_shot":
		blob_animation_player.play("idle")
	
func _process(delta):
	if not is_my_turn:
		return
	
	for player in game_state.alivePlayers:
		player.get_node("RotPivot/GunAndCameraPivot/Gun").visible = false
	gun.visible = true
	if Input.is_action_just_pressed("ui_left"):
		var init_target_index = current_target_index
		current_target_index = (current_target_index - 1 + targets.size()) % targets.size()
		update_target()
		#rotate_gun(init_target_index)
	elif Input.is_action_just_pressed("ui_right"):
		var init_target_index = current_target_index
		current_target_index = (current_target_index + 1) % targets.size()
		update_target()
		#rotate_gun(init_target_index)
	elif Input.is_action_just_pressed("ui_select"):
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
		target_label.visible = true
		return
	game_manager.useUpgrade(target, self, targetPlayerRef)
	targets.erase(target)
	current_target_index = (current_target_index + 1) % targets.size()
	update_target()
	
	
func update_target():
	var inventory_icons: Array[String] = []
	
	for item in inventory:
		if item.upgrade_type == Upgrade.UpgradeType.cigarette:
			inventory_icons.append("🚬")
		elif item.upgrade_type == Upgrade.UpgradeType.beer:
			inventory_icons.append("🍺")
		elif item.upgrade_type == Upgrade.UpgradeType.handcuff:
			inventory_icons.append("🔗")
		elif item.upgrade_type == Upgrade.UpgradeType.magGlass:
			inventory_icons.append("🔍")
		else:
			inventory_icons.append("⚡")
	
	if targets.size() > 0:
		var target = targets[current_target_index]
		target_changed.emit(target)
		if target is Player:
			game_manager.update_target_animation(target.get_node("target_for_gun").global_transform.origin)
		if target is Player:

			if target == self:
				animation_player.play("aim_self")
			else:
				animation_player.play("aim_forward")
			target_label.set_text("Target: " + target.name + "\nInventory: " + "|".join(inventory_icons) if inventory_icons.size() > 0 else "Empty")
		elif target is Upgrade:
			animation_player.play("aim_forward")
			target_label.set_text(Upgrade.UpgradeType.keys()[target.upgrade_type] + "\nInventory: " + "|".join(inventory_icons) if inventory_icons.size() > 0 else "Empty")
			if game_state.isUpgradeRound:
				for target_temp in targets:
					if target_temp.is_selected:
						game_manager.rendered_animation_object[target_temp].get_node_or_null("AnimationPlayer").play_backwards("pop up")
					target_temp.is_selected = false
				target.is_selected = true
				game_manager.rendered_animation_object[target].get_node_or_null("AnimationPlayer").play("pop up")
	else:
		animation_player.play("aim_forward")

func onTurnEnd(new_game_state: GameState, current_player_index: int):
	game_state = new_game_state
	is_my_turn = (game_state.alivePlayers[current_player_index] == self)
	target_label.visible = is_my_turn
	if !targets.is_empty():
		current_target_index = 0
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
	upgrade.reparent(self)
	upgrade.position = health_jug.position
	upgrade.position.z += 3
	var cam = Camera3D.new()
	upgrade.add_child(cam)
	cam.make_current()	

func removeInventory(upgrade: Upgrade) -> bool:
	if upgrade in inventory:
		inventory.erase(upgrade)
		return true
	return false

# Check if player has a specific upgrade
func hasUpgrade(upgrade: Upgrade) -> bool:
	return upgrade in inventory

# Apply damage to the player
func takeDamage(amount: int) -> void:
	hp -= amount
	if hp < 0:
		hp = 0
	for i in amount:
		is_playing_animation = true
		blob_animation_player.play("RESET")
		blob_animation_player.play("getting_shot")
		juice_animation_player.play("drink")
		await get_tree().create_timer(1).timeout
		juice_animation_player.play_backwards("drink")
		await get_tree().create_timer(1).timeout
		health_jug.drink()
	

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

#func rotate_gun(init_target_index):
	#var target = targets[current_target_index]
	#if target is Player:
		#animationPlayer.play(relative_position(targets[init_target_index]) + " to " + relative_position(target))
		
		
const LOCATIONS_4_PLAYERS = ["self","right","front","left"]

func relative_position(target):
	if game_state.alivePlayers.size()==4:
		var target_index = 0
		for player in game_state.alivePlayers:
			if player == target:
				break
			target_index+=1
		var self_index = 0
		for player in game_state.alivePlayers:
			if player == self:
				break
			self_index+=1
		return LOCATIONS_4_PLAYERS[(target_index - self_index + game_state.alivePlayers.size())%game_state.alivePlayers.size()]
	elif game_state.alivePlayers.size()==2:
		if target == self:
			return "self"
		else:
			return "front"


func _on_juice_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "drink_coffee":
		get_node("cup_only_new").visible = false
		
