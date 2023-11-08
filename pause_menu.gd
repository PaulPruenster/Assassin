extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()

func _on_world_toggle_game_pause(paused):
	if paused:
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_resume_pressed():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	
	hide()


func _on_exit_pressed():
	get_tree().quit()
