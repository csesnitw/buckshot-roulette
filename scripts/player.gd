extends Node3D

class_name Player

# Player properties
var hp: int
var inventory: Array = []
var power: int = 1
var isHandcuffed: bool = false
var current_target_index: int = 0
var targets: Array = []
var is_my_turn: bool = false
var game_state: GameState
@onready var target_label: Label = $CanvasLayer/TargetLabel
@onready var game_manager: Node = get_node("../GameManager")

func _init(_name: String = "Player", _hp: int = 3):
	name = _name
	hp = _hp
	inventory = []

func _ready():
	target_label.visible = false
	
func _process(delta):
	if not is_my_turn:
		return
		
	if Input.is_action_just_pressed("ui_left"):
		current_target_index = (current_target_index - 1 + targets.size()) % targets.size()
		update_target()
	elif Input.is_action_just_pressed("ui_right"):
		current_target_index = (current_target_index + 1) % targets.size()
		update_target()
	elif Input.is_action_just_pressed("ui_select"):
		if targets.size() == 0:
			return
		var target = targets[current_target_index]
		if game_state.isUpgradeRound:
			if target is Upgrade:
				game_manager.pickUpUpgrade(self, target)
		else:
			if target is Player:
				game_manager.shootPlayer(self, target)

func update_target():
	if targets.size() > 0:
		var target = targets[current_target_index]
		if target is Player:
			target_label.set_text(target.name)
		elif target is Upgrade:
			target_label.set_text(Upgrade.UpgradeType.keys()[target.upgrade_type])

func onTurnEnd(new_game_state: GameState, current_player_index: int):
	game_state = new_game_state
	is_my_turn = (game_state.alivePlayers[current_player_index] == self)
	target_label.visible = is_my_turn
	if is_my_turn:
		if game_state.isUpgradeRound:
			targets = game_state.upgradesOnTable
		else:
			targets = game_state.alivePlayers
		update_target()

# Inventory management
func addInventory(upgrade: Upgrade) -> void:
	inventory.append(upgrade)

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

# Heal the player
func heal(amount: int, max_hp: int) -> void:
	hp += amount
	if hp > max_hp:
		hp = max_hp

# Optional: check if player is alive
func isAlive() -> bool:
	return hp > 0
