extends Node3D

class_name Player

# Player properties
var hp: int
var inventory: Array = []
var power: int = 1
var isHandcuffed: bool = false

func _init(_name: String = "Player", _hp: int = 3):
	name = _name
	hp = _hp
	inventory = []

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
