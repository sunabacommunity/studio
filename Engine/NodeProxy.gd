extends Node
class_name NodeProxy

var instance: ScriptObject = null

func _enter_tree() -> void:
	if instance != null:
		if instance.has_function("onEnterTree"):
			instance.call_function("onEnterTree", [instance])

func _exit_tree() -> void:
	if instance != null:
		if instance.has_function("onExitTree"):
			instance.call_function("onExitTree", [instance])

func _ready() -> void:
	if instance != null:
		if instance.has_function("onReady"):
			instance.call_function("onReady", [instance])

func _process(delta: float) -> void:
	if instance != null:
		if instance.has_function("onProcess"):
			instance.call_function("onProcess", [instance, delta])

func _physics_process(delta: float) -> void:
	if instance != null:
		if instance.has_function("onPhysicsProcess"):
			instance.call_function("onPhysicsProcess", [instance, delta])

func _input(event: InputEvent) -> void:
	if instance != null:
		if instance.has_function("_onInput"):
			instance.call_function("_onInput", [instance, event])

func _unhandled_input(event: InputEvent) -> void:
	if instance != null:
		if instance.has_function("_onUnhandledInput"):
			instance.call_function("_onUnhandledInput", [instance, event])

func _unhandled_key_input(event: InputEvent) -> void:
	if instance != null:
		if instance.has_function("_onUnhandledKeyInput"):
			instance.call_function("_onUnhandledKeyInput", [instance, event])

func _shortcut_input(event: InputEvent) -> void:
	if instance != null:
		if instance.has_function("_onShortcutInput"):
			instance.call_function("_onShortcutInput", [instance, event])

func _notification(what: int) -> void:
	if instance != null:
		if instance.has_function("onNotification"):
			instance.call_function("onNotification", [instance, what])
