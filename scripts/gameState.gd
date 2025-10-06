extends Node

class_name GameState

# Game Manager Entities
var alivePlayers: Array[Player]
var upgradesOnTable: Array[Upgrade]
var isUpgradeRound: bool
var currRoundIndex: int = 0
var currTurnIndex: int = 0
var realCount: int
var blanksCount: int

func _init(_alivePlayers: Array[Player], _upgradesOnTable: Array[Upgrade], _isUpgradeRound: bool):
	alivePlayers = _alivePlayers
	upgradesOnTable = _upgradesOnTable
	isUpgradeRound = _isUpgradeRound
