extends Object

func load_script(path: String, args: Array) -> Object:
	var csharpScript: CSharpScript = load(path)
	
	return csharpScript.callv("new", args)
