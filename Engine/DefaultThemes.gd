extends RefCounted
class_name DefaultThemes

func get_system_theme() -> Theme:
	if DisplayServer.is_dark_mode():
		return get_dark_theme()
	else:
		return get_light_theme()

func get_light_theme() -> Theme :
	return load("res://Engine/Theme/light.tres")

func get_dark_theme() -> Theme:
	return load("res://Engine/Theme/dark.tres")
