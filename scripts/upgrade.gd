class_name Upgrade extends Node3D

enum UpgradeType {cigarette, beer, magGlass, handcuff, expiredMed, inverter, 
				  burnerPhone, handSaw, adrenaline, disableUpgrade, unoRev, wildCard}

const UPGRADEMESHMAP = {"cigarette": "juice_carton", "beer": "Cup Tea", "magGlass": "Magnifying Glass", "handcuff": "handcuffs"}
var is_selected : bool = false
var upgrade_type: UpgradeType
var pos: Vector3 # ts is for players to get pos of
var was_picked : bool = false
# ts wasn't working when isntantiating so i removed _init
	
