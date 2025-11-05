extends RefCounted

func loadScript(classname: String, obj: Object):
	if (obj == null): return
	if (obj.get_script() == null):
		var scriptPath = "res://Engine/AssetExtensions/" + classname + "AssetExtension.gd"
		var script: Script = load(scriptPath)
		obj.set_script(script)
