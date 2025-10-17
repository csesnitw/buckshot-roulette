extends CanvasLayer

@onready var box: VBoxContainer = $VBoxContainer
@onready var round_label: Label = $VBoxContainer/RoundLabel
@onready var bullet_info_label: Label = $VBoxContainer/BulletInfoLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	box.visible = false

func show_round_info(round_index: int, live_count: int, blank_count: int):
	box.visible = true
	round_label.text = "ROUND: " + str(round_index)
	bullet_info_label.text = "LIVE: " + str(live_count) + " | BLANK: " + str(blank_count)
	
	animation_player.play("fade_in")
	await animation_player.animation_finished
	animation_player.play("stay")
	await animation_player.animation_finished
	animation_player.play("fade_out")
	await animation_player.animation_finished
	queue_free()
