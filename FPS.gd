extends Label

func _process(_delta):
	var fps = Engine.get_frames_per_second()
	
	if fps < 60:
		add_theme_color_override("font_color", "red")
	else:
		add_theme_color_override("font_color", "white")
		
	text = "FPS: " + str(fps)
