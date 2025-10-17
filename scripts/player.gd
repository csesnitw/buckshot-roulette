extends Node3D

class_name Player

signal target_changed(target_node)

# Player properties
var hp: int
var inventory: Array = []
var power: int = 1
var current_target_index: int = 0
var targets: Array = []
var duplicateTargets: Array = []
var is_my_turn: bool = false
var game_state
var selectingTarget: bool = false
var pendingUpgrade: Upgrade = null

@onready var target_label: Label = $CanvasLayer/TargetLabel
@onready var currRound: Label = $CanvasLayer/TopHUD/CurrRound
@onready var bulletCounts: Label = $CanvasLayer/TopHUD/BulletCounts
@onready var lastShotLabel: Label = $CanvasLayer/TopHUD/LastShot
@onready var winnerLab: Label = $CanvasLayer/Winner
@onready var HPList: Label = $CanvasLayer/BottomHUD/HPList
@onready var game_manager: Node = get_node("../GameManager")
@onready var gun: Node3D = $Gun
@onready var animation_player: AnimationPlayer = $Gun/AnimationPlayer
@onready var health_jug = $HealthJug

func _init(_name: String = "Player", _hp: int = 3):
	name = _name
	
	inventory = []

func _ready():
	hp = game_manager.maxHP
	target_label.visible = false
	health_jug.create(game_manager.maxHP)
	
func _process(delta):
	if not is_my_turn:
		return
	
	for player in game_state.alivePlayers:
		player.get_node("Gun").visible = false
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
	if targets.size() > 0:
		var target = targets[current_target_index]
		target_changed.emit(target)
		if target:
				gun.look_at(target.global_transform.origin)
				gun.rotate_object_local(Vector3.RIGHT, 0.4) # 			Tilt down slightly
		if target is Player:

			#if target == self:
				#pass
				#animation_player.play("aim_self")
			#else:
				#pass
				#animation_player.play("aim_forward")
			target_label.set_text("Target: " + target.name)
		elif target is Upgrade:
			#animation_player.play("aim_forward")
			target_label.set_text(Upgrade.UpgradeType.keys()[target.upgrade_type])
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
	currRound.text = "Round: " + str(game_state.currRoundIndex + 1) + " Turn: " + str(game_state.currTurnIndex + 1)
	bulletCounts.text = "Bullets: " + str(game_state.realCount) + " Blanks: " + str(game_state.blanksCount)
	is_my_turn = (game_state.alivePlayers[current_player_index] == self)
	target_label.visible = is_my_turn
	if !targets.is_empty():
		current_target_index = 0
	else: 
		print("Something gones wrong")
	if(game_state.lastShot == 1):
		lastShotLabel.text = "Last Shot: Live"
	elif game_state.lastShot == 0:
		lastShotLabel.text = "Last Shot: Blank"
	else:
		lastShotLabel.text = "Last Shot: N/A"
	
	var tempHPList : String = ""
	for players in game_state.alivePlayers:
		tempHPList = tempHPList + players.name + ": " + str(players.hp) + "HP/3HP      ";
	HPList.text = tempHPList
	if is_my_turn:
		if game_state.isUpgradeRound:
			targets = remove_nulls_from_array(game_state.upgradesOnTable)
			if targets.size() == 0:
				targets = remove_nulls_from_array(game_state.alivePlayers + inventory)
		else:
			targets = remove_nulls_from_array(game_state.alivePlayers + inventory)
		update_target()

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
	for i in amount:
		health_jug.drink()
	hp -= amount
	if hp < 0:
		hp = 0

# Heal the player
func heal(amount: int, max_hp: int) -> void:
	for i in amount:
		health_jug.refill()
	hp += amount
	if hp > max_hp:
		hp = max_hp

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
