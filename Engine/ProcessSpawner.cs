using System;
using System.Collections;
using System.Collections.Generic;
using Godot;
using Godot.Collections;
using Env = System.Environment;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace Sunaba.Engine;

public partial class ProcessSpawner: Node
{
    private Process _process;
    
    public void Spawn(string cmdName, string[] args)
    {
        _process = new Process();
        var startInfo = new ProcessStartInfo
        {
            WindowStyle = ProcessWindowStyle.Hidden,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        };

        if (OS.GetName() == "Windows")
        {
            startInfo.FileName = "cmd.exe";
            startInfo.Arguments = $"/C {cmdName} {string.Join(" ", args)}";
        }
        else
        {
            if (!cmdName.IsAbsolutePath() && !cmdName.IsRelativePath() && cmdName.Contains(' '))
            {
                var cmdarr = cmdName.Split(' ');
                startInfo.FileName = cmdarr[0];
                for (int i = 1; i < cmdarr.Length; i++)
                {
                    var arg = cmdarr[i];
                    startInfo.ArgumentList.Add(arg);
                }
            }
            else
            {
                startInfo.FileName = cmdName;
        	
                if (args != null)
                {
                    // Pass arguments directly without shell interpretation
                    foreach (var arg in args)
                    {
                        startInfo.ArgumentList.Add(arg);
                    }
                }
            }
        }
	
        _process.StartInfo = startInfo;
        _process.Start();
    }

    public void Stop()
    {
        _process.Close();
    }

    private List<string> _lines = new();

    public override void _Process(double delta)
    {
        var output = _process.StandardOutput.ReadToEnd();
        foreach (var line in output.Split(Env.NewLine))
        {
            if (_lines.Contains(line))
                continue;
            
            _lines.Add(line);
            Console.WriteLine(line);
        }
    }
}