extends Node

@onready var player = $Pausable/john

signal toggle_game_pause(paused: bool)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().paused = !get_tree().paused
		emit_signal("toggle_game_pause", get_tree().paused)
		
		
func _physics_process(delta):
	get_tree().call_group("enemies", "update_target_location", player.global_transform.origin)
