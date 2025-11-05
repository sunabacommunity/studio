extends Runtime
class_name App

var io_manager: IoManager = IoManager.new()

func init(sandboxed: bool = false, classnames: PackedStringArray = []) -> void:
	init_state(sandboxed, classnames)
	
	if not sandboxed:
		if OS.get_name() == "Windows":
			var windowsSysIO = WindowsSystemIo.new()
			io_manager.Register(windowsSysIO)
		elif OS.get_name() != "Web":
			var unixSysIo = UnixSystemIo.new()
			io_manager.Register(unixSysIo)
	
	bind_object("__ioManager", io_manager)

func load_app(path: String) -> void:
	if (path.is_empty()): return
	
	if (!FileAccess.file_exists(path)): return
	
	var zipIo = IoInterfaceZip.new()
	var zipFile = FileAccess.open(path, FileAccess.READ)
	var zip_bytes = zipFile.get_buffer(zipFile.get_length())
	zipIo.LoadFromBytes(zip_bytes, "temp://")
	io_manager.Register(zipIo)
	
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
	
	do_string(io_manager.LoadText(luabin_path))

func _require(path: String) -> String:
	return io_manager.LoadText(path)

func _errord(msg: String, title: String) -> void:
	OS.alert(msg, title)
	printerr(msg)

func _warnd(msg: String, title: String) -> void:
	OS.alert(msg, title)

func _infod(msg: String, title: String) -> void:
	OS.alert(msg, title)
