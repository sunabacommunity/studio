extends Node3D
class_name InfoPrefab

var prefab_path: String  = ""
var prefab_name: String = ""
var map_properties: Dictionary = {}

func _func_godot_apply_properties(entity_properties: Dictionary):
	prefab_path = entity_properties["path"]
	prefab_name = entity_properties["name"]
	map_properties = entity_properties
