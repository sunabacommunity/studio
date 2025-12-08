extends VBoxContainer

@onready var window_title_label = $Titlebar/WIndowTitle


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var window = get_window()
	if (OS.get_name() == "macOS"):
		window.extend_to_title = true
		window.maximize_disabled = true
		window.minimize_disabled = true
	else:
		window.borderless = true
	window.unresizable = true
	
	var closeButton = $Titlebar/HBox/CloseButton
	if (OS.get_name() == "Windows"):
		var button_sys_font = SystemFont.new()
		button_sys_font.font_names = [
			"Segoe MDL2 Assets",
			"Segoe UI Symbol",
			"Arial Unicode MS"
		]
		closeButton.add_theme_font_override("font", button_sys_font)
	elif (OS.get_name() == "macOS"):
		closeButton.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	window_title_label.text = get_window().title


var titlebar_lmb_pressed := false

func _on_spacer_gui_input(event: InputEvent) -> void:
	var window = get_window()
	if (window == null):
		return
	
	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && !titlebar_lmb_pressed):
		titlebar_lmb_pressed = true
		window.start_drag()
	elif (!Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && titlebar_lmb_pressed):
		titlebar_lmb_pressed = false


func _on_close_button_pressed() -> void:
	var window = get_window()
	if (window == null):
		return
	
	window.emit_signal("close_requested")
