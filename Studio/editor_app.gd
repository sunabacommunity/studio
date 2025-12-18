extends DesktopApp
class_name EditorApp

func printlnInit():
	DotNetOutputRedirect.connect("Println", func (msg: String):
		printMsg([msg])
	)

var output: PackedStringArray = []
signal on_print(msg: String)

func _print(msgarr: PackedStringArray) -> void:
	printMsg(msgarr)

func printMsg(msgarr: PackedStringArray):
	var final_msg = ""
	for msg in msgarr:
		final_msg += msg
		if (msg != msgarr.get(msgarr.size())):
			final_msg += " "
	output.append(final_msg)
	on_print.emit(final_msg)
