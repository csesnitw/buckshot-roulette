class_name Upgrade extends Node3D

enum UpgradeType {cigarette, beer, magGlass, handcuff, expiredMed, inverter, 
				  burnerPhone, handSaw, adrenaline, disableUpgrade, unoRev, wildCard}

const UPGRADEMESHMAP = {"cigarette": "juice_carton", "beer": "Cup Tea", "magGlass": "Magnifying Glass"}

var upgrade_type: UpgradeType
var pos: Vector3 # ts is for players to get pos of
# ts wasn't working when isntantiating so i removed _init
	
