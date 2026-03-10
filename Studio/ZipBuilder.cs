using System;
using System.Buffers.Text;
using System.IO;
using System.IO.Compression;
using Godot;

namespace Sunaba.Studio;

public partial class ZipBuilder : RefCounted
{
    private string tempPath = "";

    public ZipBuilder()
    {
        
    }
    
    public void CreateZip(string path)
    {
        tempPath = path + "_output/";

        if (!Directory.Exists(tempPath))
        {
            Directory.CreateDirectory(tempPath);
        }
    }

    public void AddToZipFile(string path, string bytes)
    {
        var tempFilePath = tempPath + path;
        CreateDir(tempFilePath.GetBaseDir());
        File.WriteAllBytes(tempFilePath, Marshalls.Base64ToRaw(bytes));
    }

    public void CreateDir(string path)
    {
        var baseDir = path.GetBaseDir();
        if (baseDir == tempPath) return;
        if (!Directory.Exists(baseDir))
        {
            CreateDir(baseDir);
        }
        if (!Directory.Exists(path))
        {
            Directory.CreateDirectory(path);
        }
    }

    public void BuildZip(string path)
    {
        if (File.Exists(path))
        {
            File.Delete(path);
        }
        ZipFile.CreateFromDirectory(tempPath, path);
    }
}