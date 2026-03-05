using System;
using System.Collections.Generic;
using Godot;
using System.Reflection;

namespace Sunaba.Engine.Interop;

public partial class DotNetObject: RefCounted
{
    protected readonly object Obj;

    public DotNetObject()
    {
        Obj = null;
    }

    public DotNetObject(object obj)
    {
        Obj = obj;
    }

    public Variant GetMember(string varName)
    {
        var properties = Obj.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
        foreach (var prop in properties)
        {
            if (prop.Name == varName)
            {
                var value = prop.GetValue(Obj);
                if (value != null)
                {
                    return Obj2Variant(value);
                }
            }
        }
        return new Variant();
    }

    public static Variant Obj2Variant(object obj)
    {
        if (obj is Variant variant)
        {
            return variant;
        }
        else if (obj is string stringValue)
        {
            return stringValue;
        }
        else if (obj is bool boolValue)
        {
            return boolValue;
        }
        else if (obj is int intValue)
        {
            return intValue;
        }
        else if (obj is float floatValue)
        {
            return floatValue;
        }
        else if (obj is double doubleValue)
        {
            return doubleValue;
        }
        else if (obj is decimal decimalValue)
        {
            float f = (float)decimalValue;
            return f;
        }
        else if (obj is long longValue)
        {
            return longValue;
        }
        else if (obj is ulong ulongValue)
        {
            return ulongValue;
        }
        else if (obj is byte[] byteArray)
        {
            return byteArray;
        }
        else
        {
            return new DotNetObject(obj);
        }
    }

    public static object Variant2Obj(Variant variant)
    {
        if (variant.Obj is DotNetObject dotNetObject)
        {
            return dotNetObject.Obj;
        }
        else if (variant.VariantType == Variant.Type.Object)
        {
            GodotObject godotObject = (GodotObject)variant;
        }
        else if (variant.VariantType == Variant.Type.String)
        {
            return variant.AsString();
        }
        else if (variant.VariantType == Variant.Type.Bool)
        {
            return variant.AsBool();
        }
        else if (variant.VariantType == Variant.Type.Int)
        {
            return variant.AsInt32();
        }
        else if (variant.VariantType == Variant.Type.Float)
        {
            return variant.AsSingle();
        }
        else if (variant.VariantType == Variant.Type.PackedByteArray)
        {
            return variant.AsByteArray();
        }

        return null;
    }

    public void SetMember(string varName, Variant value)
    {
        var properties  = Obj.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
        foreach (var prop in properties)
        {
            if (prop.Name == varName)
            {
                prop.SetValue(Obj, Variant2Obj(value));
            }
        }
    }

    public Variant CallMethod(string name, Array args)
    {
        var methods = Obj.GetType().GetMethods(BindingFlags.Public | BindingFlags.Instance);
        List<object> argList = new List<object>();
        foreach (Variant arg in args)
        {
            argList.Add(Variant2Obj(arg));
        }
        foreach (var methodInfo in methods)
        {
            if (methodInfo.Name == name)
            {
                var result = methodInfo.Invoke(Obj, argList.ToArray());
                return Obj2Variant(result);
            }
        }

        return new Variant();
    } 
}