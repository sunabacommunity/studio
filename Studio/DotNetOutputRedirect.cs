using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Environment = System.Environment;

public partial class DotNetOutputRedirect : Node
{
	private List<string> _out = new();
	private StringWriter _stringWriter = new StringWriter();

	[Signal]
	public delegate void PrintlnEventHandler(string line);
	
	// Called when the node enters the scene tree for the first time.
	public DotNetOutputRedirect()
	{
		Console.SetOut(_stringWriter);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		var lines = _stringWriter.ToString()
			.Split(new[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);
		foreach (var line in lines)	
		{
			if (_out.Contains(line))
				continue;
			
			GD.Print(line);
			_out.Add(line);
			EmitSignalPrintln(line);
		}	
	}
}

