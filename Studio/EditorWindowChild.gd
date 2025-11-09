extends DesktopApp

func _exit(exitcode: int) -> void:
	get_window().queue_free()
