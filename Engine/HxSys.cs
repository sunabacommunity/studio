using System.Collections;
using Godot;
using Godot.Collections;
using Env = System.Environment;
using System.Diagnostics;

namespace Sunaba.Engine;

public partial class HxSys: RefCounted
{
	public Dictionary Environment()
	{
		var envVar = Env.GetEnvironmentVariables();
		var environment = new Dictionary();
		foreach (DictionaryEntry dictionaryEntry in envVar)
		{
			environment[(string)dictionaryEntry.Key] = (string)dictionaryEntry.Value;
		}

		return environment;
	}

	public int Command(string cmdName, string[] args)
	{
		string argsStr = args.Join(" ");
		var process = new Process();
		ProcessStartInfo startInfo = new ProcessStartInfo();
		startInfo.WindowStyle = ProcessWindowStyle.Hidden;
		startInfo.FileName = "cmd.exe";
		startInfo.Arguments = $"/C {cmdName} {argsStr}";
		process.StartInfo = startInfo;
		process.Start();
		process.WaitForExit();
		return process.ExitCode;
	}
}
