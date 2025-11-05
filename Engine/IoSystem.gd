extends RefCounted

func create_file_system_io():
	return FileSystemIo.new()

func create_windows_system_io():
	return WindowsSystemIo.new()

func create_unix_system_io():
	return UnixSystemIo.new()
