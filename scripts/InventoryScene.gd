extends Control

# Reference to all inventory slot labels
@onready var inventory_slots: Array = []

# Normal and highlighted text sizes
const NORMAL_TEXT_SIZE = 32
const HIGHLIGHTED_TEXT_SIZE = 48

# Reference to the currently highlighted label
var current_highlighted_label: Label = null

func _ready():
	# Collect all inventory slot labels
	var grid = $Panel/MarginContainer/GridContainer
	for i in range(15):
		var slot = grid.get_node("Slot" + str(i + 1))
		var label = slot.get_node("Label")
		inventory_slots.append(label)
		
		# Set initial text size for all labels
		label.add_theme_font_size_override("font_size", NORMAL_TEXT_SIZE)

# Main function to be called externally
# upgrade_array: Array of Upgrade objects
# current_index: Index of the currently selected slot (0-14)
func updateInventory(upgrade_array: Array, current_index: int) -> void:
	# Fill inventory slots with icons
	fillInventorySlots(upgrade_array)
	
	# Highlight the current slot
	if current_index >= 0 and current_index < upgrade_array.size():
		increaseLabelTextSize(inventory_slots[current_index])
	else:
		resetHighlights()

# Fill inventory slots with corresponding icons
func fillInventorySlots(upgrade_array: Array) -> void:
	# Reset all labels first
	for i in range(inventory_slots.size()):
		if i < upgrade_array.size() and upgrade_array[i] != null:
			# Get icon for this upgrade
			var icon = getInventoryIcon(upgrade_array[i])
			inventory_slots[i].text = icon
		else:
			# Empty slot
			inventory_slots[i].text = ""
		
		# Reset text size to normal
		inventory_slots[i].add_theme_font_size_override("font_size", NORMAL_TEXT_SIZE)

# Get icon representation for an upgrade
func getInventoryIcon(upgrade: Upgrade) -> String:
	if upgrade.upgrade_type == Upgrade.UpgradeType.cigarette:
		return "🧃"
	elif upgrade.upgrade_type == Upgrade.UpgradeType.beer:
		return "☕"
	elif upgrade.upgrade_type == Upgrade.UpgradeType.handcuff:
		return "🔗"
	elif upgrade.upgrade_type == Upgrade.UpgradeType.magGlass:
		return "🔍"
	elif upgrade.upgrade_type == Upgrade.UpgradeType.handSaw:
		return "💊"
	else:
		return "⚡"

# Increase text size for the highlighted label
func increaseLabelTextSize(label: Label) -> void:
	# Reset previous highlighted label if exists
	if current_highlighted_label != null and current_highlighted_label != label:
		current_highlighted_label.add_theme_font_size_override("font_size", NORMAL_TEXT_SIZE)
	
	# Set new highlighted label
	current_highlighted_label = label
	label.add_theme_font_size_override("font_size", HIGHLIGHTED_TEXT_SIZE)

# Optional helper function to reset all highlights
func resetHighlights() -> void:
	for label in inventory_slots:
		label.add_theme_font_size_override("font_size", NORMAL_TEXT_SIZE)
	current_highlighted_label = null
