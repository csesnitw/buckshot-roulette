extends Node

signal turn_ended(gameState, currPlayerTurnIndex)
var rendered_animation_object = {}
var gameState: GameState = null # given to every player at the end of a turn
var upgradeScene: PackedScene = null
var players: Array[Player] = []
var currPlayerTurnIndex: int = 0 
var shotgunShells: Array[int] = [] # 0 for blank, 1 for live
var roundIndex: int = 0
var shotgunShellCount: int = 8 # some logic based on round index
var initShotgunShellCount: int = 2 # think of this as bullets per player at round index 1, (this gets multiplied by round index asw and curr alive players)
var realShots: int = 0;
var blanks: int = 0;
var maxHP: int = 5 # temporary value
var table: Node3D = null;
var gun: Node3D = null
var blankShot: bool = false # im kinda stupid this needs refactoring this is only used to check if u shot urself!! 
var sfxPlayer: AudioStreamPlayer; # call this guys funcs to play any sfx  
var fuckedUpPlayerToViewportMap: Dictionary = {}
var windowRefs = []
var current_target_node: Node3D = null
var isFirstHandSawUsed: bool = false
var gun_transfer_animation_playing: bool = false
var last_turn_player_ref: Player = null
#for gun animation
const GUN_ROTATION_DURATION : float = 0.5

#for transition effect
const ROUND_START_INFO_SCENE = preload("res://scenes//RoundStartInfo.tscn")

func _process(delta): 
	pass

# Game Logic functions
func initMatch() -> void:
	# add logic here to set up initial players and scene (can only really do this once the scene is done)
	# scene work ig would need to be done to actually call this func
	# one this fumc is called though a continuous match SHOULD work.
	# as for UI changes and stuff best to have them as side effects of functions here i think.
	upgradeScene = preload("res://scenes/upgrade.tscn")
	roundIndex = 0
	shotgunShellCount = 8
	for sibs in get_parent().get_children():
		#print(get_parent().get_children())
		if sibs is Player:
			players.append(sibs)
			var connectedControllers = Input.get_connected_joypads()
			if players.size() <= connectedControllers.size():
				players[-1].controllerID = connectedControllers[players.size() - 1]
			else:
				players[-1].controllerID = -1
			
	sfxPlayer = get_node("../SFXPlayer")
	gun = get_node("../Gun")
	gun.position = Vector3(0, -0.2, 0)
	gameState = GameState.new(players, [], false)
	gameState.currRoundIndex = roundIndex # TODO: get rid of this var entirely (roundIndex)
	for player in players:
		player.game_state = gameState
		self.turn_ended.connect(player.onTurnEnd)
		player.target_changed.connect(on_player_target_changed)
	table = get_node("../Table")
	initRound()

func initRound() -> void:
	# figure out a way to randomly generate upgrade scenes and spawn them into the world
	if roundIndex != 0:
		gameState.isUpgradeRound = true
		generateRandomUpgrades() # doesnt work yet
		spawnUpgradesOnTable()
		currPlayerTurnIndex = randi() % gameState.alivePlayers.size() # added this here due to a weird bug with UI if any other player other than the main viewport starts the game
		for playerRef in gameState.alivePlayers: #all players look at centre
			update_target_animation(playerRef, Vector3(0,-0.5,0))
	gameState.currRoundIndex = roundIndex
	gameState.currTurnIndex = 0
	shotgunShellCount = initShotgunShellCount * (roundIndex + 1) * gameState.alivePlayers.size()# maybe give this more thought
	# use real and blanks to show at the start of a round for a bit
	var minRealShots = floor(shotgunShellCount * 1/4)
	var maxRealShots = floor(shotgunShellCount * 4/5)
	realShots = randi() % (shotgunShellCount - minRealShots + maxRealShots ) + minRealShots
	blanks = shotgunShellCount - realShots
	# disgusting, TODO: refactor later
	gameState.realCount = realShots
	gameState.blanksCount = blanks
	generateRandomBulletsOrder() # aka shuffle

	for player in gameState.alivePlayers:
		var player_gun = player.get_node_or_null("RotPivot/GunAndCameraPivot/Gun")
		if player_gun && player!=gameState.alivePlayers[currPlayerTurnIndex]:
			player_gun.visible = false
	
	
	print("Window REFS: ", windowRefs)
	var exit_signals: Array[Signal] = []
	var info_overlay = ROUND_START_INFO_SCENE.instantiate()
	var overlayDup = info_overlay.duplicate()
	get_tree().root.add_child(overlayDup)
	overlayDup.show_round_info(roundIndex + 1, realShots, blanks)
	exit_signals.append(overlayDup.tree_exiting)
	for player_window in windowRefs:
		var subviewport_container = player_window.get_child(0)
		var subviewport = subviewport_container.get_child(0)
		var overlayDupWin = info_overlay.duplicate() # reusing overlayDup 
		subviewport.add_child(overlayDupWin)
		await get_tree().process_frame # dumb caveat
		overlayDupWin.show_round_info(roundIndex + 1, realShots, blanks)
		exit_signals.append(overlayDup.tree_exiting)
	
	
	#TODO: remove these when UI done but rn useful for debugging
	print( "Current players turn: " + str(currPlayerTurnIndex))
	print("Game State: ")
	print(gameState.alivePlayers)
	print(gameState.upgradesOnTable)
	
	
	# show round specific UI to all players
	
	turn_ended.emit(gameState, currPlayerTurnIndex)

func endTurn() -> void:
	if(shotgunShells.size() == 0):
		roundIndex += 1
		initRound()
		return
		
	if blankShot:
		blankShot = false
	else:
		currPlayerTurnIndex = (currPlayerTurnIndex + 1) % gameState.alivePlayers.size()
		transfer_gun_animation(last_turn_player_ref)
		update_target_animation(last_turn_player_ref, Vector3(0,-0.5,0)) #look to centre
	
	gameState.currTurnIndex += 1
	if(gameState.isUpgradeRound):
		spawnUpgradesOnTable()
		
	if gameState.isUpgradeRound && is_all_nulls(gameState.upgradesOnTable):
		gameState.isUpgradeRound = false
		currPlayerTurnIndex -= 1
		if(currPlayerTurnIndex == -1):
			currPlayerTurnIndex = gameState.alivePlayers.size() - 1
		# to ensure the player who picked the last upgrade gets the first shot
		# if we are adding UI based on this change the above
		
		# now here would probably be a good time to flash the number of reals and blanks
		
	# maybe we could allow players to use upgrades like handcuffs during the upgrade pickup sesh?
	while gameState.alivePlayers[currPlayerTurnIndex] in gameState.handCuffedPlayers:
		var handcuffed_player = gameState.alivePlayers[currPlayerTurnIndex]
		gameState.handCuffedPlayers.erase(handcuffed_player) # in the actual buckshot roulette handcuffs are broken after a full circle of the skipped turn so might have to change this
		var anim_player = handcuffed_player.get_node("RotPivot/blob/AnimationPlayer")
		anim_player.play("idle")
		currPlayerTurnIndex = (currPlayerTurnIndex + 1) % gameState.alivePlayers.size()
	
	# once all turn loggic is done with, send a signal to all players to refetch gameState
	print( "Current players turn: " + str(currPlayerTurnIndex))
	print("Game State: ")
	print(gameState.alivePlayers)
	print(gameState.upgradesOnTable)
	gun.set_target_player(gameState.alivePlayers[currPlayerTurnIndex])
	turn_ended.emit(gameState, currPlayerTurnIndex)
	
	
	
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
	# cleaned up jeff code 
	gameState.upgradesOnTable.clear()
	var numUpgrades = 8 * roundIndex
	var availableTypes = []
	if roundIndex == 1:
		availableTypes = [
			Upgrade.UpgradeType.cigarette,
			Upgrade.UpgradeType.beer,
			Upgrade.UpgradeType.magGlass
		]
	elif roundIndex == 2:
		availableTypes = [
			Upgrade.UpgradeType.cigarette,
			Upgrade.UpgradeType.beer,
			Upgrade.UpgradeType.magGlass,
			Upgrade.UpgradeType.handSaw,
			Upgrade.UpgradeType.handcuff
		]
	else:
		availableTypes = Upgrade.UpgradeType.values()

	for i in range(numUpgrades):
		var randomType = availableTypes[randi() % availableTypes.size()]
		var newUpgrade = Upgrade.new()
		newUpgrade.upgrade_type = randomType
		gameState.upgradesOnTable.append(newUpgrade)

func animate_removal(child): #for upgrade ddisappear animation
	if(is_instance_valid(child)):
		child.disappear_animation_playing = true
		child.get_node("AnimationPlayer").play("disappear")
		await get_tree().create_timer(0.5).timeout
		child.queue_free()
	else:
		print("deselect upgrade animation error")

# curr plan is to recall this every upgrade turn
func spawnUpgradesOnTable():
	for child in table.get_children():
		if child is Upgrade:
			if child.was_picked == true and not child.disappear_animation_playing:
				animate_removal(child)
			elif not child.disappear_animation_playing:
				child.queue_free()
	
	var tableX: float = 2
	var tableZ: float = 2
	var total_upgrades = gameState.upgradesOnTable.size()
	if total_upgrades == 0:
		return
	
	var columns: int = ceil(sqrt(total_upgrades))
	var rows: int = ceil(float(total_upgrades) / columns)
	
	var spacingX: float = tableX / columns
	var spacingZ: float = tableZ / rows

	# Offsets so grid is centered
	var startX: float = -((columns - 1) * spacingX) / 2.0
	var startZ: float = -((rows - 1) * spacingZ) / 2.0
	
	var x = 0
	rendered_animation_object = {}
	for i in range(total_upgrades):
		if rows%2 == 1 && i == int(total_upgrades/2): #empty center for gun
			x+=1
		if gameState.upgradesOnTable[i] == null: #for empty slots
			x+=1
			continue
		

		var upgradeInstance: Upgrade = upgradeScene.instantiate() as Upgrade #upgrades on table are different from upgradesOnTable array
		#use rendered_animation_object map to get actual upgrades on table
		upgradeInstance.upgrade_type = gameState.upgradesOnTable[i].upgrade_type
		upgradeInstance.get_node("Label3D").set_text(Upgrade.UpgradeType.keys()[upgradeInstance.upgrade_type])
		upgradeInstance.is_selected = gameState.upgradesOnTable[i].is_selected
		if Upgrade.UpgradeType.keys()[upgradeInstance.upgrade_type] in Upgrade.UPGRADEMESHMAP.keys():
			upgradeInstance.get_node(
				Upgrade.UPGRADEMESHMAP[Upgrade.UpgradeType.keys()[upgradeInstance.upgrade_type]]
			).visible = true
		rendered_animation_object[gameState.upgradesOnTable[i]] = upgradeInstance
		var row: int = x / columns   
		var col: int = x % columns
		if upgradeInstance.is_selected:
			upgradeInstance.get_node("AnimationPlayer").play("pop up")
		var pos = Vector3(
			startX + col * spacingX,
			0.53,
			startZ + row * spacingZ
		)

		upgradeInstance.position = pos
		gameState.upgradesOnTable[i].pos = pos
		table.add_child(upgradeInstance)
		
		x+=1

		
# Below are all functions that are player facing, call these when designing players for player devs
func endGame() -> void:
	var winner: Player = gameState.alivePlayers[0]

	# TODO: Should revamp/remove player label

	# Handle the game end screen in the main scene
	var main_scene = get_tree().root.get_child(0)
	main_scene.handleEndGame(winner.name)

	sfxPlayer.stream_paused = false
	return

func getGameState() -> GameState:
	return gameState

func shootPlayer(callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	# logic for shooting
	if(gameState.isUpgradeRound):
		return
	
	if(callerPlayerRef != gameState.alivePlayers[currPlayerTurnIndex]):
		return # not ur goddamn turn
	var currBull : int = shotgunShells.pop_front()
	
	gameState.lastShot = currBull
	last_turn_player_ref = callerPlayerRef
	if currBull == 1:
		sfxPlayer.playShoot()
	else:
		sfxPlayer.playBlank()
		if callerPlayerRef == targetPlayerRef:
			blankShot = true
			print("BLANK and shot urself")
	var dmg = currBull * callerPlayerRef.power
	targetPlayerRef.takeDamage(dmg)
	if(targetPlayerRef.hp == 0):
		for i in range(gameState.alivePlayers.size()):
			if(gameState.alivePlayers[i] == targetPlayerRef):
				gameState.alivePlayers.pop_at(i)
				break
	callerPlayerRef.power = 1
	print("Shoot called by: ", callerPlayerRef.name)
	print("Damage: ", dmg)
	print(targetPlayerRef.name, " hp now: ", targetPlayerRef.hp)
	if checkWin():
		endGame()
	else:
		endTurn()
# call this when you want to pick an upgrade off of the upgrade table
func pickUpUpgrade(callerPlayerRef: Player, upgradeRef: Upgrade) -> void:
	if !gameState.isUpgradeRound:
		return
	if(callerPlayerRef != gameState.alivePlayers[currPlayerTurnIndex]):
		return # not ur goddamn turn
	for i in range(gameState.upgradesOnTable.size()):
		if gameState.upgradesOnTable[i] == upgradeRef:
			callerPlayerRef.addInventory(upgradeRef)
			gameState.upgradesOnTable[i]=null
			break
	rendered_animation_object[upgradeRef].was_picked = true
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
		Upgrade.UpgradeType.expiredMed:
			useExpiredMed(callerPlayerRef)
		Upgrade.UpgradeType.inverter:
			useInverter(callerPlayerRef)
		Upgrade.UpgradeType.burnerPhone:
			useBurnerPhone(callerPlayerRef)
		Upgrade.UpgradeType.handSaw:
			useHandSaw(callerPlayerRef)
		Upgrade.UpgradeType.wildCard:
			# Generating random upgrade from 0-7
			var newUpgrade = Upgrade.new()
			newUpgrade.upgrade_type = Upgrade.UpgradeType.values()[randi() % 8]
			useUpgrade(newUpgrade, callerPlayerRef, targetPlayerRef)
		
	callerPlayerRef.inventory.erase(upgradeRef)

func useCigarette(callerPlayerRef: Player) -> void:
	callerPlayerRef.heal(1, maxHP)

func useBeer(callerPlayerRef: Player) -> void:
	var popped = shotgunShells.pop_front()
	callerPlayerRef.get_node("cup_only_new").visible = true
	callerPlayerRef.get_node("JuiceAnimationPlayer").play("drink_coffee")
	# Play animation of popped bullet being ejected
	if shotgunShells.size() == 0:
		endTurn()

func useMagGlass(callerPlayerRef: Player) -> void:
	print(shotgunShells[0]) # replace with animation for callerPlayerRef

func useHandcuff(callerPlayerRef: Player, targetPlayerRef: Player) -> void:
	var anim_player = targetPlayerRef.get_node("RotPivot/blob/AnimationPlayer")
	anim_player.play("handcuffed")
	gameState.handCuffedPlayers.append(targetPlayerRef)

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
	gun.saw_off_barrel()

func _ready():
	await get_tree().process_frame # fixed ghost code (seriously should use a signal probably)
	initMatch()  

func on_player_target_changed(target_node):
	current_target_node = target_node

func is_all_nulls(upgradesOnTable : Array[Upgrade]):
	for upgrade in upgradesOnTable:
		if upgrade != null:
			return false
	return true

func update_target_animation(player: Player, target_pos):
	while gun_transfer_animation_playing:
		await  get_tree().process_frame
	var start_rot
	var end_rot
	var to_tween = []
	# For other players (not Player1)
	if player.name != "Player1":
		var me = fuckedUpPlayerToViewportMap[player]
		start_rot = me.rotation
		me.look_at(target_pos, Vector3.UP)
		end_rot = me.rotation
		end_rot.y = wrapf(end_rot.y, start_rot.y - PI, start_rot.y + PI)

		to_tween.append([me, start_rot, end_rot])

	# Gun pivot rotation
	var pivot = player.get_node("RotPivot/GunAndCameraPivot")
	start_rot = pivot.rotation
	pivot.look_at(target_pos, Vector3.UP)
	end_rot = pivot.rotation
	to_tween.append([pivot, start_rot, end_rot])
	
	start_rot = player.gun.rotation
	player.gun.look_at(target_pos, Vector3.UP)
	end_rot = player.gun.rotation
	player.gun.visible = true
	to_tween.append([player.gun, start_rot, end_rot])
	
	for tween_info in to_tween:
		tween_info[0].rotation = tween_info[1]
		var tween = get_tree().create_tween()
		tween.tween_property(tween_info[0], "rotation", tween_info[2], GUN_ROTATION_DURATION)


func self_target_animation(player : Player):
	while gun_transfer_animation_playing:
		await  get_tree().process_frame
	var table_center = Vector3(0, -0.5, 0)
	var to_tween = []
	if player.name != "Player1":
		var me = fuckedUpPlayerToViewportMap[player]
		var me_start_rot = me.rotation
		me.look_at(table_center, Vector3.UP)
		var me_end_rot = me.rotation
		me_end_rot.y = wrapf(me_end_rot.y, me_start_rot.y - PI, me_start_rot.y + PI)
		to_tween.append([me, me_start_rot, me_end_rot])

	var pivot = player.get_node("RotPivot/GunAndCameraPivot")
	var pivot_start_rot = pivot.rotation
	pivot.look_at(table_center, Vector3.UP)
	var pivot_end_rot = pivot.rotation
	to_tween.append([pivot, pivot_start_rot, pivot_end_rot])

	var gun_node = player.gun
	gun_node.visible = true
	var gun_start_rot = gun_node.rotation
	var target_pos = fuckedUpPlayerToViewportMap[player].global_transform.origin
	gun_node.look_at(target_pos, Vector3.UP)
	var gun_end_rot = gun_node.rotation
	gun_end_rot.y = wrapf(gun_end_rot.y, gun_start_rot.y - PI, gun_start_rot.y + PI)
	to_tween.append([gun_node, gun_start_rot, gun_end_rot])

	for tween_info in to_tween:
		tween_info[0].rotation = tween_info[1]
		var tween = get_tree().create_tween()
		tween.tween_property(tween_info[0], "rotation", tween_info[2], GUN_ROTATION_DURATION)
	
func transfer_gun_animation(from_player: Player):
	if gameState.alivePlayers.size()<=1:
		return
	gun_transfer_animation_playing = true
	var destination_gun = gameState.alivePlayers[currPlayerTurnIndex].get_node("RotPivot/GunAndCameraPivot/Gun")
	var start_gun = from_player.get_node("RotPivot/GunAndCameraPivot/Gun")
	var copy_to_animate = start_gun.duplicate()
	copy_to_animate.global_transform = start_gun.global_transform
	start_gun.visible = false
	copy_to_animate.visible = true
	add_child(copy_to_animate)
	var start_rot = copy_to_animate.global_rotation
	var end_rot = destination_gun.global_rotation
	end_rot.y = wrapf(end_rot.y, start_rot.y - PI, start_rot.y + PI)
	var tween = get_tree().create_tween()
	tween.tween_property(copy_to_animate, "global_position", destination_gun.global_position, 1)
	tween = get_tree().create_tween()
	tween.tween_property(copy_to_animate, "global_rotation", end_rot, 1)
	await tween.finished
	destination_gun.visible = true
	copy_to_animate.queue_free()
	gun_transfer_animation_playing = false
