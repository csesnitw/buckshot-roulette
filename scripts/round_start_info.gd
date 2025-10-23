extends CanvasLayer

@onready var box: VBoxContainer = $VBoxContainer
@onready var round_label: Label = $VBoxContainer/RoundLabel
@onready var bullet_info_label: Label = $VBoxContainer/BulletInfoLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	box.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_round_info(round_index: int, live_count: int, blank_count: int):
	get_tree().paused = true
	box.visible = true
	round_label.text = "ROUND: " + str(round_index)
	bullet_info_label.text = "LIVE: " + str(live_count) + " | BLANK: " + str(blank_count)
	
	animation_player.play("fade_in")
	await animation_player.animation_finished
	animation_player.play("stay")
	await animation_player.animation_finished
	animation_player.play("fade_out")
	await animation_player.animation_finished
	get_tree().paused = false
	queue_free()

func show_bullet_type(bullet_type_text: String):
	box.visible = true
	round_label.text = ""
	bullet_info_label.text = bullet_type_text
	
	animation_player.play("fade_in")
	await animation_player.animation_finished
	animation_player.play("stay")
	await animation_player.animation_finished
	animation_player.play("fade_out")
	await animation_player.animation_finished
	queue_free()

func show_death_message():
	box.visible = true
	round_label.text = "YOU ARE DEAD"
	bullet_info_label.text = ""
	
	animation_player.play("fade_in")
	await animation_player.animation_finished
	animation_player.play("stay")
	await animation_player.animation_finished
	animation_player.play("fade_out")
	await animation_player.animation_finished
	queue_free()
