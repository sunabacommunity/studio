extends InfoPrefab


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		$PlayerModel.queue_free()
