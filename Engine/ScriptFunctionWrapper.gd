extends Object
class_name ScriptFunctionWrapper

var function: ScriptFunction = null
var object: ScriptObject = null

func call_func(...args) -> void:
	var array = []
	if object != null:
		array.append(object)
	for arg in args:
		array.append(arg)
	function.call_func(array)

func to_callable() -> Callable:
	return Callable(self, "call_func")
