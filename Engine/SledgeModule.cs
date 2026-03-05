using System;
using System.IO;
using System.Reflection;
using Godot;
using Sledge.Formats.GameData;
using Sunaba.Engine.Interop;
using Sledge.Formats.Geometric;
using Sledge.Formats.Map.Formats;

namespace Sunaba.Engine;

public partial class SledgeModule: Node
{
    public void Bind(DotNetInteropService interopService)
    {
        interopService.AddType(typeof(MemoryStream));
        interopService.AddType(typeof(StreamWriter));
        var asm1 = typeof(Box).Assembly;
        _bindAsm(interopService, asm1);
        var asm2 = typeof(FgdFormat).Assembly;
        _bindAsm(interopService, asm2);
        var asm3 = typeof(QuakeMapFormat).Assembly;
        _bindAsm(interopService, asm3);
    }

    private void _bindAsm(DotNetInteropService interopService, Assembly assembly)
    {
        foreach (Type type in assembly.ExportedTypes)
        {
            interopService.AddType(type);
        }
    }
}