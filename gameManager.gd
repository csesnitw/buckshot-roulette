extends Node

# Initializing the game state
var gameState: GameState = GameState.new([], [])
var players: Array[Player] = []
var currPlayerTurnIndex: int = 0 
var shotgunShells: Array[int] = [] # 0 for blank, 1 for live
var roundIndex: int = 0
var shotgunShellCount: int = 8 # some logic based on round index
var initShotgunShellCount: int = 8
var minRealShots: int = 2
var realShots: int = 0;
var blanks: int = 0;
var maxHP: int = 3 # temporary value
var isUpgradeRnd : bool = false # false means players can shoot, true means its upgrade pickup round
# Game Logic functions
func initMatch() -> void:
	# add logic here to set up initial players and scene (can only really do this once the scene is done)
	# scene work ig would need to be done to actually call this func
	# one this fumc is called though a continuous match SHOULD work.
	# as for UI changes and stuff best to have them as side effects of functions here i think.
	roundIndex = 0
	shotgunShellCount = 8
	initRound()

func initRound() -> void:
	# figure out a way to randomly generate upgrade scenes and spawn them into the world
	if roundIndex != 0:
		generateRandomUpgrades() # doesnt work yet
	
	shotgunShellCount = initShotgunShellCount * (roundIndex + 1) # maybe give this more thought
	# use real and blanks to show at the start of a round for a bit
	realShots = randi() % (shotgunShellCount - minRealShots) + minRealShots
	blanks = shotgunShellCount - realShots
	generateRandomBulletsOrder() # aka shuffle
	if roundIndex != 0:
		isUpgradeRnd = true
	currPlayerTurnIndex = randi() % gameState.alivePlayers.size()
	

func endTurn() -> void:
	if(shotgunShells.size() == 0):
		roundIndex += 1
		initRound()
		return
	
	currPlayerTurnIndex = (currPlayerTurnIndex + 1) % gameState.alivePlayers.size()
	
	if isUpgradeRnd && gameState.upgradesOnTable.size() == 0:
		isUpgradeRnd = false
		currPlayerTurnIndex -= 1
		if(currPlayerTurnIndex == -1):
			currPlayerTurnIndex = gameState.alivePlayers.size() - 1
		# to ensure the player who picked the last upgrade gets the first shot
		# if we are adding UI based on this change the above
		
		# now here would probably be a good time to flash the number of reals and blanks
		 

	# maybe we could allow players to use upgrades like handcuffs during the upgrade pickup sesh?
	while gameState.alivePlayers[currPlayerTurnIndex].isHandcuffed:
		gameState.alivePlayers[currPlayerTurnIndex].isHandcuffed = false # in the actual buckshot roulette handcuffs are broken after a full circle of the skipped turn so might have to change this
		currPlayerTurnIndex = (currPlayerTurnIndex + 1) % gameState.alivePlayers.size()
	
func checkWin() -> bool:
	return gameState.alivePlayers.size() == 1

func generateRandomBulletsOrder():
	shotgunShells.clear()
	var remainingReal = realShots
	var remainingBlank = blanks

	for i in range(shotgunShellCount):
		if remainingReal > 0 && remainingBlank > 0:
			var choice = randi() % 2
			if choice == 1:
				shotgunShells.append(1)
				remainingReal -= 1
			else:
				shotgunShells.append(0)
				remainingBlank -= 1
		elif remainingReal > 0:
			shotgunShells.append(1)
			remainingReal -= 1
		elif remainingBlank > 0:
			shotgunShells.append(0)
			remainingBlank -= 1

func generateRandomUpgrades():
	# Progressive upgrade generation based on round number
	# More upgrades and higher-tier ones appear as rounds increase
	gameState.upgradesOnTable.clear()

	# Number of upgrades increases with round
	var num_upgrades = 2 + roundIndex 

	# Upgrade tiers: early rounds = common, later = rare/powerful upgrades
	var available_types = []
	if roundIndex == 0:
		available_types = [
			Upgrade.UpgradeType.cigarette,
			Upgrade.UpgradeType.beer,
			Upgrade.UpgradeType.magGlass
		]
	elif roundIndex == 1:
		available_types = [
			Upgrade.UpgradeType.cigarette,
			Upgrade.UpgradeType.beer,
			Upgrade.UpgradeType.magGlass,
			Upgrade.UpgradeType.handSaw,
			Upgrade.UpgradeType.handcuff
		]
	# unlock all upgrades from round 3 onwards	
	else:
		available_types = Upgrade.UpgradeType.values() 

	# Randomly populate table
	for i in range(num_upgrades):
		var random_type = available_types[randi() % available_types.size()]
		var new_upgrade = Upgrade.new(random_type)
		gameState.upgradesOnTable.append(new_upgrade)


# Below are all functions that are player facing, call these when designing players for player devs
func endGame() -> void:
	# do something like announce winner or change ui here later
	return

func getGameState() -> GameState:
	return gameState

func shootPlayer(callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	# logic for shooting
	if(isUpgradeRnd):
		return
	if(callerPlayerRef != gameState.alivePlayers[currPlayerTurnIndex]):
		return # not ur goddamn turn
	var currBull : int = shotgunShells.pop_front()
	var dmg = currBull * callerPlayerRef.power
	targetPlayerRef.takeDamage(dmg)
	if(targetPlayerRef.hp == 0):
		for i in range(gameState.alivePlayers.size()):
			if(gameState.alivePlayers[i] == targetPlayerRef):
				gameState.alivePlayers.pop_at(i)
				break
	callerPlayerRef.power = 1
	if checkWin():
		endGame()
	endTurn()

# call this when you want to pick an upgrade off of the upgrade table
func pickUpUpgrade(callerPlayerRef: Player, upgradeRef: Upgrade) -> void:
	if !isUpgradeRnd:
		return
	if(callerPlayerRef != gameState.alivePlayers[currPlayerTurnIndex]):
		return # not ur goddamn turn
		
	for i in range(gameState.upgradesOnTable.size()):
		if gameState.upgradesOnTable[i] == upgradeRef:
			callerPlayerRef.addInventory(upgradeRef)
			gameState.upgradesOnTable.pop_at(i)
			break
	endTurn()
	
	
	
# TODO: need to add logic for specific upgrades, e.g. cannot use handsaw when already used (power already 2).
func useUpgrade(upgradeRef: Upgrade, callerPlayerRef: Player, targetPlayerRef: Player = null) -> void:
	if upgradeRef not in callerPlayerRef.inventory:
		return
	
	match upgradeRef.upgrade_type:
		Upgrade.UpgradeType.cigarette:
			useCigarette(callerPlayerRef)
		Upgrade.UpgradeType.beer:
			useBeer(callerPlayerRef)
		Upgrade.UpgradeType.magGlass:
			useMagGlass(callerPlayerRef)
		Upgrade.UpgradeType.handcuff:
			useHandcuff(callerPlayerRef, targetPlayerRef)
		Upgrade.UpgradeType.unoRev:
			useUnoRev(callerPlayerRef, targetPlayerRef)
		Upgrade.UpgradeType.expiredMed:
			useExpiredMed(callerPlayerRef)
		Upgrade.UpgradeType.inverter:
			useInverter(callerPlayerRef)
		Upgrade.UpgradeType.burnerPhone:
			useBurnerPhone(callerPlayerRef)
		Upgrade.UpgradeType.adrenaline:
			useAdrenaline(callerPlayerRef, targetPlayerRef)
		Upgrade.UpgradeType.handSaw:
			useHandSaw(callerPlayerRef)
		Upgrade.UpgradeType.disableUpgrade:
			useDisableUpgrade(callerPlayerRef, targetPlayerRef)
		Upgrade.UpgradeType.wildCard:
			# Generating random upgrade from 0-7
			var newUpgrade = Upgrade.new(Upgrade.UpgradeType.values()[randi() % 8])
			useUpgrade(newUpgrade, callerPlayerRef, targetPlayerRef)
		
	callerPlayerRef.inventory.erase(upgradeRef)

func useCigarette(callerPlayerRef: Player) -> void:
	callerPlayerRef.heal(1, maxHP)

func useBeer(callerPlayerRef: Player) -> void:
	var popped = shotgunShells.pop_front()
	# Play animation of popped bullet being ejected
	if shotgunShells.size() == 0:
		endTurn()

func useMagGlass(callerPlayerRef: Player) -> void:
	print(shotgunShells[0]) # replace with animation for callerPlayerRef

func useHandcuff(callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	targetPlayerRef.isHandcuffed = true

func useExpiredMed(callerPlayerRef: Player) -> void:
	if randi()%2:
		callerPlayerRef.heal(2, maxHP)
	else:
		callerPlayerRef.takeDamage(1)

func useInverter(callerPlayerRef: Player) -> void: 
	for i in range(shotgunShells.size()):
		shotgunShells[i] ^= 1
	# callerPlayerRef isn't needed for the logic, but will need to play animation.

func useBurnerPhone(callerPlayerRef: Player) -> void:
	if shotgunShells.size() >= 1:
		print(shotgunShells[1]) # replace with animation for callerPlayerRef
	else:
		print(0) # play animation showing empty shell 
	
func useHandSaw(callerPlayerRef: Player) -> void:
	callerPlayerRef.power += 1
	# also need to show gun being sawed off

# will implement these upgrades after Prototype 1
func useAdrenaline(callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	pass
	
func useUnoRev(callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	pass

func useDisableUpgrade(callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	pass
