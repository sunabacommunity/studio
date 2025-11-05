extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var args = OS.get_cmdline_args()
	var sproj: String = ""
	for arg in args:
		if (arg.ends_with(".sproj")):
			if (arg.is_absolute_path() || arg.is_relative_path()):
				sproj = arg
				break
	
	if (sproj.is_empty()):
		get_tree().change_scene_to_file("res://Studio/splash.tscn")
