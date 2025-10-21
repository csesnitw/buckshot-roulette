class_name Upgrade extends Node3D

enum UpgradeType {cigarette, beer, magGlass, handcuff, handSaw}

const UPGRADEMESHMAP = {
 "cigarette": "juice_carton_pivot",
 "beer": "tea_cup_pivot",
 "magGlass": "magnifying_glass_pivot",
 "handcuff": "pool_floatie_pivot",
 "handSaw": "handsaw_pivot"
}
var is_selected : bool = false
var upgrade_type: UpgradeType
var pos: Vector3 # ts is for players to get pos of
var was_picked : bool = false
var disappear_animation_playing = false
# ts wasn't working when isntantiating so i removed _init
	
