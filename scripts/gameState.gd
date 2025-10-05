extends Node

class_name GameState

# Game Manager Entities
var alivePlayers: Array[Player]
var upgradesOnTable: Array[Upgrade]

func _init(_alivePlayers: Array[Player], _upgradesOnTable: Array[Upgrade]):
	alivePlayers = _alivePlayers
	upgradesOnTable = _upgradesOnTable
