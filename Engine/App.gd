extends Runtime
class_name App

var io_manager: IoManager = IoManager.new()
var dotnet_interop: DotNetInteropService = DotNetInteropService.new()

func init(sandboxed: bool = false, classnames: PackedStringArray = []) -> void:
	init_state(sandboxed, classnames)
	
	add_child(dotnet_interop)
	SledgeModule.Bind(dotnet_interop)
	
	bind_object("__ioManager", io_manager)
	set_var("__can_debug", false)
	bind_object("__dotnetInterop", dotnet_interop)

func load_library(path: String) -> String:
	if (path.is_empty()): return ""
	
	if (!FileAccess.file_exists(path)): return ""
	
	var zipIo: IoInterface
	if (path.begins_with("res://") or path.begins_with("user://")):
		var _zipIo = ZipIo.new()
		_zipIo.Open(path, "temp://")
		zipIo = _zipIo
	else:
		var ioInterfaceZip = IoInterfaceZip.new()
		ioInterfaceZip.Open(path, "temp://")
		zipIo = ioInterfaceZip
	io_manager.Register(zipIo)
	
	if (!zipIo.FileExists("temp://header.json")):
		_errord("header.json not found in the snb file", "Inavlid header file")
		return ""
	var header_json : String = zipIo.LoadText("temp://header.json")
	if (header_json.is_empty()):
		_errord("header.json not found in the snb file", "Inavlid header file")
		return ""
	
	var header: Dictionary = JSON.parse_string(header_json)
	
	zipIo.SetPathUrl(header["rootUrl"])
	
	return header["rootUrl"]

func load_app(path: String) -> void:
	if (path.is_empty()): return
	
	if (!FileAccess.file_exists(path)): return
	
	var zipIo: IoInterface
	if (path.begins_with("res://") or path.begins_with("user://")):
		var _zipIo = ZipIo.new()
		_zipIo.Open(path, "temp://")
		zipIo = _zipIo
	else:
		var ioInterfaceZip = IoInterfaceZip.new()
		ioInterfaceZip.Open(path, "temp://")
		zipIo = ioInterfaceZip
	io_manager.Register(zipIo)
	
	if (!io_manager.FileExists("temp://header.json")):
		_errord("header.json not found in the snb file", "Inavlid header file")
		return
	var header_json : String = io_manager.LoadText("temp://header.json")
	if (header_json.is_empty()):
		_errord("header.json not found in the snb file", "Inavlid header file")
		return
	
	var header: Dictionary = JSON.parse_string(header_json)
	
	var appName: String = header.get("name", "Sunaba")
	
	var app_base_user_dir_path = ProjectSettings.globalize_path("user://appdata/")
	if not DirAccess.dir_exists_absolute(app_base_user_dir_path):
		DirAccess.make_dir_absolute(app_base_user_dir_path)
	var app_user_dir_path = app_base_user_dir_path + appName + "/"
	if not DirAccess.dir_exists_absolute(app_user_dir_path):
		DirAccess.make_dir_absolute(app_user_dir_path)
	
	var user_io = FileSystemIo.new()
	user_io.Open(app_user_dir_path, "user://")
	io_manager.Register(user_io)
	
	var type: String = header.get("type", "executable")
	
	if type != "executable":
		_errord("type must be executable", "Error")
		return
	
	var luabin_name = header.get("luabin", "main.lua")
	zipIo.SetPathUrl(header["rootUrl"])
	
	var luabin_path = zipIo.GetPathUrl() + luabin_name
	
	var lua_package_dir = "user://lua_packages"
	if (!DirAccess.dir_exists_absolute(lua_package_dir)):
		DirAccess.make_dir_absolute(lua_package_dir)
	set_var("__userPackages", ProjectSettings.globalize_path(lua_package_dir))
	do_string("package.path = package.path .. ';' .. __userPackages  ..  '/?.lua'")
	
	var new_bit32_path = lua_package_dir + "/bit32.lua"
	if (!FileAccess.file_exists(new_bit32_path)):
		var old_bit32_path = "res://bit32.lua"
		var old_file = FileAccess.open(old_bit32_path, FileAccess.READ)
		var file_contents = old_file.get_as_text()
		old_file.close()
		var new_file = FileAccess.open(new_bit32_path, FileAccess.WRITE)
		new_file.store_string(file_contents)
		new_file.close()
	
	var new_mobdebug_path = lua_package_dir + "/mobdebug.lua"
	if (!FileAccess.file_exists(new_bit32_path)):
		var old_mobdebug_path = "res://mobdebug.lua"
		var old_file = FileAccess.open(old_mobdebug_path, FileAccess.READ)
		var file_contents = old_file.get_as_text()
		old_file.close()
		var new_file = FileAccess.open(new_mobdebug_path, FileAccess.WRITE)
		new_file.store_string(file_contents)
		new_file.close()
	
	do_string(io_manager.LoadText(luabin_path))

func enable_debugging():
	set_var("__can_debug", true)

func _require(path: String) -> String:
	return io_manager.LoadText(path)

func _errord(msg: String, title: String) -> void:
	var accept_dialog: AcceptDialogPlus = AcceptDialogPlus.new()
	accept_dialog.SetIconType(0)
	accept_dialog.title = title
	accept_dialog.set("Text", msg)
	accept_dialog.confirmed.connect(func():
		accept_dialog.queue_free()
	)
	accept_dialog.close_requested.connect(func():
		accept_dialog.queue_free()
	)
	add_child(accept_dialog)
	accept_dialog.hide()
	accept_dialog.theme = DefaultThemes.new().get_system_theme()
	accept_dialog.popup_centered()
	printerr(msg)

func _warnd(msg: String, title: String) -> void:
	var accept_dialog: AcceptDialogPlus = AcceptDialogPlus.new()
	accept_dialog.SetIconType(1)
	accept_dialog.title = title
	accept_dialog.set("Text", msg)
	accept_dialog.confirmed.connect(func():
		accept_dialog.queue_free()
	)
	accept_dialog.close_requested.connect(func():
		accept_dialog.queue_free()
	)
	add_child(accept_dialog)
	accept_dialog.hide()
	accept_dialog.theme = DefaultThemes.new().get_system_theme()
	accept_dialog.popup_centered()

func _infod(msg: String, title: String) -> void:
	var accept_dialog: AcceptDialogPlus = AcceptDialogPlus.new()
	accept_dialog.SetIconType(2)
	accept_dialog.title = title
	accept_dialog.set("Text", msg)
	accept_dialog.confirmed.connect(func():
		accept_dialog.queue_free()
	)
	accept_dialog.close_requested.connect(func():
		accept_dialog.queue_free()
	)
	add_child(accept_dialog)
	accept_dialog.hide()
	accept_dialog.theme = DefaultThemes.new().get_system_theme()
	accept_dialog.popup_centered()

func _exit(exitcode: int) -> void:
	get_tree().quit(exitcode)
