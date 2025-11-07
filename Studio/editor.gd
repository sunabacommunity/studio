extends DesktopApp


func _init() -> void:
	init(false, [])
	var args = OS.get_cmdline_args()
	var sproj_path = ""
	for arg in args:
		if arg.ends_with(".sproj"):
			sproj_path = arg
			break
	if (sproj_path != ""):
		set_var("projectPath", sproj_path)
	var asm_dir = StudioUtils.GetBaseDirectory()
	if asm_dir.contains("\\"):
		asm_dir = asm_dir.replace("\\", "/")
	if not asm_dir.ends_with("/"):
		asm_dir += "/"
	var snb_path = asm_dir + "editor.snb"
	load_app(snb_path)
