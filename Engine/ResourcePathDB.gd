extends Node

var _paths: Dictionary[Resource, String]

func get_res_path(res: Resource)-> String:
	if not has_res_path(res): return ""
	return _paths[res]

func set_res_path(res: Resource, path: String):
	_paths[res] = path

func has_res_path(res: Resource):
	return _paths.has(res)

func get_res_count() -> int:
	return _paths.keys().size()
