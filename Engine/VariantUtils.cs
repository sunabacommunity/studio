using Godot;
using Godot.Collections;
using GdArray = Godot.Collections.Array;
using GdDictionary = Godot.Collections.Dictionary;
using System;
using System.Collections.Generic;

namespace Sunaba.Engine;

class VariantUtils
{
    public static GdDictionary ScgDictToGdDict(System.Collections.Generic.Dictionary<string, object> dictionary)
    {
        GdDictionary gdDictionary = new();

        foreach (var kvp in dictionary)
        {
            var obj = kvp.Value;
            var variant = ObjToVariant(obj);
            gdDictionary[kvp.Key] = variant;
        }

        return gdDictionary;
    }
    
    public static System.Collections.Generic.Dictionary<string, object> GdDictToScgDict(GdDictionary gdDictionary)
    {
        System.Collections.Generic.Dictionary<string, object> dictionary = new();

        foreach (var key in gdDictionary.Keys)
        {
            var value = gdDictionary[key];
            var obj = VariantToObj(value);
            dictionary[key.ToString()] = obj;
        }

        return dictionary;
    }
    
    public static GdArray ScgListToGdArray(System.Collections.Generic.List<object> list)
    {
        GdArray gdArray = new();

        foreach (var item in list)
        {
            var variant = ObjToVariant(item);
            gdArray.Add(variant);
        }

        return gdArray;
    }
    
    public static List<object> GdArrayToScgList(GdArray gdArray)
    {
        List<object> list = new();

        foreach (var item in gdArray)
        {
            var obj = VariantToObj(item);
            list.Add(obj);
        }

        return list;
    }
    
    public static Variant ObjToVariant(object obj)
    {
        Variant variant;
        if (obj is System.Collections.Generic.Dictionary<string, object> subdict)
        {
            variant = ScgDictToGdDict(subdict);
        }
        else if (obj is System.Collections.Generic.List<object> sublist)
        {
            variant = ScgListToGdArray(sublist);
        }
        else if (obj is string str)
        {
            variant = str;
        }
        else if (obj is int i)
        {
            variant = i;
        }
        else if (obj is float f)
        {
            variant = f;
        }
        else if (obj is bool b)
        {
            variant = b;
        }
        else if (obj is long l)
        {
            variant = l;
        }
        else if (obj is double d)
        {
            variant = d;
        }
        else if (obj is byte[] bytes)
        {
            variant = bytes;
        }
        else if (obj is string[] strArray)
        {
            variant = strArray;
        }
        else if (obj is int[] intArray)
        {
            variant = intArray;
        }
        else if (obj is float[] floatArray)
        {
            variant = floatArray;
        }
        else if (obj is long[] longArray)
        {
            variant = longArray;
        }
        else if (obj is double[] doubleArray)
        {
            variant = doubleArray;
        }
        else if (obj is object[] objArray)
        {
            GdArray gdArray = new();
            foreach (var item in objArray)
            {
                gdArray.Add(ObjToVariant(item));
            }
            variant = gdArray;
        }
        else
        {
            variant = new Variant();
        }

        return variant;
    }
    
    public static object VariantToObj(Variant variant)
    {
        if (variant.VariantType == Variant.Type.Array)
        {
            List<object> objects = new();
            var array = variant.AsGodotArray();
            foreach (var item in array)
            {
                objects.Add(VariantToObj(item));
            }
            return objects;
        }
        else if (variant.VariantType == Variant.Type.Dictionary)
        {
            System.Collections.Generic.Dictionary<string, object> dict = new();
            var gdDict = variant.AsGodotDictionary();
            foreach (var key in gdDict.Keys)
            {
                var value = gdDict[key];
                dict[key.ToString()] = VariantToObj(value);
            }
            return dict;
        }
        else if (variant.VariantType == Variant.Type.Bool)
        {
            bool b = variant.AsBool();
            return b;
        }
        else if (variant.VariantType == Variant.Type.Int)
        {
            int i = variant.AsInt32();
            return i;
        }
        else if (variant.VariantType == Variant.Type.Float)
        {
            float f = variant.AsSingle();
            return f;
        }
        else if (variant.VariantType == Variant.Type.String)
        {
            string s = variant.AsString();
            return s;
        }
        else if (variant.VariantType == Variant.Type.PackedByteArray)
        {
            byte[] bytes = variant.AsByteArray();
            return bytes;
        }
        else if (variant.VariantType == Variant.Type.PackedInt32Array)
        {
            int[] intArray = variant.AsInt32Array();
            return intArray;
        }
        else if (variant.VariantType == Variant.Type.PackedFloat32Array)
        {
            float[] floatArray = variant.AsFloat32Array();
            return floatArray;
        }
        else if (variant.VariantType == Variant.Type.PackedInt64Array)
        {
            long[] longArray = variant.AsInt64Array();
            return longArray;
        }
        else if (variant.VariantType == Variant.Type.PackedFloat64Array)
        {
            double[] doubleArray = variant.AsFloat64Array();
            return doubleArray;
        }
        else if (variant.VariantType == Variant.Type.PackedStringArray)
        {
            string[] strArray = variant.AsStringArray();
            return strArray;
        }
        else
        {
            return null;
        }
    }
}