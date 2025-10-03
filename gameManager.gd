extends Node

class GameState:
	var alivePlayers: Array[Player]
	var upgradesOnTable: Array[Upgrade]

	func _init(_alivePlayers: Array, _upgradesOnTable: Array):
		alivePlayers = _alivePlayers
		upgradesOnTable = _upgradesOnTable
		
# TODO: make the Player class please and Upgrade too
var gameState: GameState = GameState.new([], [])
var players: Array[Player] = []
var currPlayerTurnIndex: int = 0 
var shotgunShells: Array[int] = [] # 0 for blank, 1 for live
var tableUpgrades: Array[Upgrades] = []
var roundIndex: int = 0;
var shotgunShellCount: int = 8; # some logic based on round index

# Game Logic functions
func initMatch() -> void:
	roundIndex = 0
	shotgunShellCount = 8;

func initRound() -> void:
	currPlayerTurnIndex = 0

func endTurn() -> void:
	currPlayerTurnIndex += 1

func checkWin() -> bool:
	return alivePlayers.size() == 1;

func generateRandomBullets():
	shotgunShells.clear()
	for i in range(shotgunShellCount):
		var shell = randi() % 2  
		shotgunShells[i] = shell

# Below are all functions that are player facing, call these when designing players for player devs
func endGame() -> void:
	return
func getGameState() -> GameState:
	return gameState

func shootPlayer(callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	# logic for shooting
	if checkWin():
		endGame()
	endTurn()

# call this when you want to pick an upgrade off of the upgrade table
# returns true if succesffuly picked up
# otherwise returns false
func pickUpUpgrade(callerPlayerRef: Player, upgradeRef: Upgrade) -> boolean:
	# im guessing i need to include logic in the scene to actually add and remove upgrades from the table visually
	var gotUpgrade: bool = false
	var upIndex: int = -1
	for i in tableUpgrades.size():
		if upgradeRef == tableUpgrades[i]:
			gotUpgrade = true
			upIndex = i
	if gotUpgrade:
		callerPlayerRef.addInventory(upgradeRef)
		tableUpgrades.pop_at(i)
	else:
		return false
	return true

func useUpgrade(upgradeRef: Upgrade, callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	
# Upgrade devs fill out the space below with your upgrade logics

# RULES FOR MATCHES & ROUNDS 

# Start a new match (resets everything and begins round 1)
func startMatch() -> void:
	roundIndex = 0
	shotgunShellCount = 8
	startRound()

# Start a new round
func startRound() -> void:
	roundIndex += 1
	currPlayerTurnIndex = 0
	shotgunShells.clear()
	for i in range(shotgunShellCount):
		var shell = randi() % 2
		shotgunShells.append(shell)
	# prepare upgrades for this round
	prepareUpgradesForRound()
	# upgrade draft phase before shooting starts
	upgradeDraftPhase()
	# last player to pick shoots first
	currPlayerTurnIndex = gameState.alivePlayers.size() - 1

# End a player's turn and go to the next one
func nextTurn() -> void:
	currPlayerTurnIndex += 1
	if currPlayerTurnIndex >= gameState.alivePlayers.size():
		currPlayerTurnIndex = 0
	if checkWin():
		endGame()

# Shooting logic using shotgun shells
func resolveShot(callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	if shotgunShells.size() == 0:
		startRound()
		return
	var shell: int = shotgunShells[0]
	shotgunShells.pop_at(0)
	if shell == 1:
		targetPlayerRef.takeDamage(1)
		if not targetPlayerRef.isAlive:
			gameState.alivePlayers.erase(targetPlayerRef)
	else:
		# blank shot, nothing happens
		pass
	if checkWin():
		endGame()
	else:
		nextTurn()

#Upgrade draft phase & scaling upgrades

# Add upgrades to the table depending on round number
func prepareUpgradesForRound() -> void:
	tableUpgrades.clear()
	var upgradeCount: int = 2 + roundIndex
	for i in range(upgradeCount):
		var upgrade: Upgrade = generateUpgradeForRound(roundIndex)
		tableUpgrades.append(upgrade)
	gameState.upgradesOnTable = tableUpgrades

# Example upgrade generation (placeholder)
func generateUpgradeForRound(rnd: int) -> Upgrade:
	var upgrade: Upgrade = Upgrade.new()
	upgrade.powerLevel = clamp(rnd, 1, 5)
	return upgrade

# Players draft upgrades before shooting phase
func upgradeDraftPhase() -> void:
	if tableUpgrades.size() == 0:
		return
	var startIndex: int = randi() % gameState.alivePlayers.size()
	var pickIndex: int = startIndex
	while tableUpgrades.size() > 0:
		var player: Player = gameState.alivePlayers[pickIndex]
		var chosenUpgrade: Upgrade = tableUpgrades.pop_back()
		player.addInventory(chosenUpgrade)
		pickIndex = (pickIndex + 1) % gameState.alivePlayers.size()
