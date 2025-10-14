extends Node3D

var float_speed = 1.0
var float_amplitude = 0.1
var time_passed = 0.0

var target_player = null # For the table gun, set by GameManager
var aim_target_pos = null # For the player's gun, set by Player.gd

func _process(delta):
	if aim_target_pos:
		# This is a player's gun being aimed.
		look_at(aim_target_pos, Vector3.UP)
	elif target_player:
		# This is the table gun pointing at the current player.
		var target_position = target_player.global_transform.origin
		var gun_position = global_transform.origin
		var direction = (target_position - gun_position).normalized()
		var look_at_position = global_transform.origin + direction
		look_at_position.y = global_transform.origin.y
		look_at(look_at_position, Vector3.UP)

func set_target_player(player):
	target_player = player
