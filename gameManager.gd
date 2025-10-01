extends Node

class GameState:
	var alivePlayers
	var upgradesOnTable

	func _init(_alivePlayers: Array, _upgradesOnTable: Array):
		alivePlayers = _alivePlayers
		upgradesOnTable = _upgradesOnTable
		
# TODO: make the Player class please and Upgrade too
var gameState: GameState = GameState.new([], [])
var players = []
var currPlayerTurnIndex: int = 0 
var shotgunShells: Array[int] = [] # 0 for blank, 1 for live
var tableUpgrades = []
var roundIndex: int = 0
var shotgunShellCount: int = 8 # some logic based on round index

# ======================================================
# GAME LOGIC FUNCTIONS
# ======================================================

func initMatch() -> void:
	# Start a new match (first round)
	roundIndex = 0
	shotgunShellCount = 8
	initRound()

func initRound() -> void:
	# Prepare new round
	currPlayerTurnIndex = 0
	roundIndex += 1
	# Reset shotgun shells for this round
	generateRandomBullets()
	# Reset upgrades on table if needed
	tableUpgrades.clear()
	# Ensure all alive players are still in GameState
	gameState.alivePlayers = players.filter(func(p): return p.isAlive)

func endTurn() -> void:
	# Move to next alive player
	currPlayerTurnIndex += 1
	if currPlayerTurnIndex >= gameState.alivePlayers.size():
		currPlayerTurnIndex = 0
	# If only one player alive → match ends
	if checkWin():
		endGame()

func checkWin() -> bool:
	return gameState.alivePlayers.size() == 1

func generateRandomBullets():
	shotgunShells.clear()
	for i in range(shotgunShellCount):
		var shell = randi() % 2  
		shotgunShells.append(shell)

# ======================================================
# PLAYER-FACING FUNCTIONS
# ======================================================

func endGame() -> void:
	print("Game Over! Winner: ", gameState.alivePlayers[0].name if gameState.alivePlayers.size() == 1 else "None")

func getGameState() -> GameState:
	return gameState

func shootPlayer(callerPlayerRef, targetPlayerRef) -> void:
	# Take the next shell from the shotgun
	if shotgunShells.size() == 0:
		# If no shells left, start a new round
		initRound()
		return
	
	var shell = shotgunShells.pop_front()
	
	if shell == 1:
		# Live round, target takes damage
		targetPlayerRef.takeDamage(1)
		print("%s shot %s with a live round!" % [callerPlayerRef.name, targetPlayerRef.name])
		if not targetPlayerRef.isAlive:
			gameState.alivePlayers.erase(targetPlayerRef)
	else:
		# Blank round
		print("%s shot %s with a blank round." % [callerPlayerRef.name, targetPlayerRef.name])
	
	# Check if round ended
	if checkWin():
		endGame()
	else:
		endTurn()

func pickUpUpgrade(callerPlayerRef, upgradeRef) -> bool:
	var gotUpgrade: bool = false
	var upIndex: int = -1
	for i in range(tableUpgrades.size()):
		if upgradeRef == tableUpgrades[i]:
			gotUpgrade = true
			upIndex = i
	if gotUpgrade:
		callerPlayerRef.addInventory(upgradeRef)
		tableUpgrades.pop_at(upIndex)
		return true
	return false

func useUpgrade(upgradeRef, callerPlayerRef, targetPlayerRef) -> void:
	
