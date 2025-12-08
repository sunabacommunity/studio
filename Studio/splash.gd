extends DesktopApp


func _init() -> void:
	init(false, [])
	var asm_dir = StudioUtils.GetBaseDirectory()
	if asm_dir.contains("\\"):
		asm_dir = asm_dir.replace("\\", "/")
	if not asm_dir.ends_with("/"):
		asm_dir += "/"
	var snb_path = asm_dir + "splashscreen.snb"
	load_app(snb_path)

func _ready() -> void:
	PlatformService.PlatformName = "Sunaba Player"
	$TextureRect.queue_free()
