extends Control

# Reference to all inventory slot labels
@onready var inventory_slots: Array = []
@onready var slot_details: Label = $Label

# Normal and highlighted text sizes
const NORMAL_TEXT_SIZE = 32
const HIGHLIGHTED_TEXT_SIZE = 48
const SLOT_VERBOSE_MODE = true  # set this to false to disable the label

# Reference to the currently highlighted label
var current_highlighted_label: Label = null

func _ready():
	# turn the slot detail label on or off
	slot_details.visible = SLOT_VERBOSE_MODE
	
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
		var details = getInventoryIconAndName(upgrade_array[current_index])
		if SLOT_VERBOSE_MODE:
			slot_details.set_text(details["name"])
	else:
		resetHighlights()
		if SLOT_VERBOSE_MODE:
			slot_details.set_text("")

# Fill inventory slots with corresponding icons
func fillInventorySlots(upgrade_array: Array) -> void:
	# Reset all labels first
	for i in range(inventory_slots.size()):
		if i < upgrade_array.size() and upgrade_array[i] != null:
			# Get icon for this upgrade
			var details = getInventoryIconAndName(upgrade_array[i])
			inventory_slots[i].text = details["icon"]
		else:
			# Empty slot
			inventory_slots[i].text = ""
		
		# Reset text size to normal
		inventory_slots[i].add_theme_font_size_override("font_size", NORMAL_TEXT_SIZE)

# Get icon representation for an upgrade
func getInventoryIconAndName(upgrade: Upgrade) -> Dictionary[String, String]:
	if upgrade.upgrade_type == Upgrade.UpgradeType.cigarette:
		return {"icon": "🧃", "name": "JUICE: Instantly pour a juice from the carton to your glass."}
	elif upgrade.upgrade_type == Upgrade.UpgradeType.beer:
		return {"icon": "☕", "name": "COFFEE: Racks the shotgun, ejecting the current shell."}
	elif upgrade.upgrade_type == Upgrade.UpgradeType.handcuff:
		return {"icon": "🛟", "name": "POOL FLOATIE: Forces the opponent to skip their next turn."}
	elif upgrade.upgrade_type == Upgrade.UpgradeType.magGlass:
		return {"icon": "🔍", "name": "MAG GLASS: Reveals the type of the current shell in the chamber."}
	elif upgrade.upgrade_type == Upgrade.UpgradeType.handSaw:
		return {"icon": "💊", "name": "PILL: Damage gets incremented if its a live shot with stacked pills."}
	else:
		return {"icon": "⚡", "name": "POWER UP: Boosts your character with an unknown effect."}

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
