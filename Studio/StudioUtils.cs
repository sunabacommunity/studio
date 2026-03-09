using Godot;
using System;
using System.Runtime.InteropServices;

public partial class StudioUtils : Node
{
	public string GetBaseDirectory()
	{
		return AppDomain.CurrentDomain.BaseDirectory;
	}

	public string GetToolchainDirectory()
	{
		var baseDir = GetBaseDirectory();
		if (OS.HasFeature("editor"))
		{
			baseDir = ProjectSettings.GlobalizePath("res://");
		}
		var toolchainDirectory = baseDir + "/toolchain/";
		if (OS.GetName() == "Windows")
		{
			toolchainDirectory += "windows-x86_64/";
		}
		else if (OS.GetName() == "Linux")
		{
			toolchainDirectory += "linux";
			if (RuntimeInformation.ProcessArchitecture == Architecture.X64)
			{
				toolchainDirectory += "-x86_64/";
			}
			else
			{
				return "";
			}
		}
		else if (OS.GetName() == "macOS")
		{
			
			toolchainDirectory += "mac";
			if (RuntimeInformation.ProcessArchitecture == Architecture.Arm64)
			{
				toolchainDirectory += "-arm64";
			}
			else
			{
				toolchainDirectory += "-x86_64";
			}
		}
		else
		{
			return "";
		}

		return toolchainDirectory;
	}
}
