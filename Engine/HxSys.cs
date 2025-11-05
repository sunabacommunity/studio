using System.Collections;
using Godot;
using Godot.Collections;
using Env = System.Environment;

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
}
