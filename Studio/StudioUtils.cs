using Godot;
using System;

public partial class StudioUtils : Node
{
	public string GetBaseDirectory()
	{
		return AppDomain.CurrentDomain.BaseDirectory;
	}
}
