using System;
using System.Collections.Generic;
using System.Reflection;
using Godot;

namespace Sunaba.Engine.Interop;

[GlobalClass]
public partial class DotNetInteropService : Node
{
    private readonly List<Type> _types = new List<Type>();

    public void AddType(Type type)
    {
        _types.Add(type);
    }

    public bool HasType(Type type)
    {
        return _types.Contains(type);
    }

    public void RemoveType(Type type)
    {
        _types.Remove(type);
    }

    public DotNetObject Instantiate(string className, Array args)
    {
        List<object> argList = new List<object>();
        foreach (Variant arg in args)
        {
            argList.Add(DotNetObject.Variant2Obj(arg));
        }
        foreach (var type in _types)
        {
            if (className == type.FullName)
            {
                return new DotNetObject(Activator.CreateInstance(type, argList.ToArray()));
            }
        }

        return null;
    }

    public Variant CallStatic(string className, string methodName, Array args)
    {
        List<object> argList = new List<object>();
        foreach (Variant arg in args)
        {
            argList.Add(DotNetObject.Variant2Obj(arg));
        }
        foreach (var type in _types)
        {
            if (className == type.FullName)
            {
                var method = type.GetMethod(methodName);
                if (method != null)
                {
                    var res = method.Invoke(null, argList.ToArray());
                    return DotNetObject.Obj2Variant(res);
                }
            }
        }

        return new Variant();
    }
}