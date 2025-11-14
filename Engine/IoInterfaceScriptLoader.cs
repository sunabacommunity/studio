using System.IO;
using MoonSharp.Interpreter;
using MoonSharp.Interpreter.Loaders;

namespace Sunaba.Engine;

public class IoInterfaceScriptLoader : ScriptLoaderBase
{
	private IoInterface _ioInterface;

	public IoInterfaceScriptLoader(IoInterface ioInterface)
	{
		_ioInterface = ioInterface;
	}

	public override bool ScriptFileExists(string name)
	{
		return _ioInterface.FileExists(name);
	}

	public override object LoadFile(string file, Table globalContext)
	{
		var code = _ioInterface.LoadText(file);
		if (code == null)
		{
			throw new FileNotFoundException("File not found: " + file + ":" + _ioInterface.GetFilePath(file));
		}
		return code;
	}

	public override string ResolveFileName(string filename, Table globalContext)
	{
		return filename;
	}

	public override string ResolveModuleName(string modname, Table globalContext)
	{
		return modname;
	}
}
