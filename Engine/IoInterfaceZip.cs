using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using Godot.Collections;
using Godot;
using System.Linq;

namespace Sunaba.Engine;

[GlobalClass]
public partial class IoInterfaceZip : SystemIoBase
{
    public String Path;
    public String AltPath;
    public String AltPath2;

    public IoInterfaceZip()
    {
    }

    public override void SaveBytes(string assetPath, byte[] bytes)
    {
    }

    public override void SaveText(string assetPath, string text)
    {
    }

    public override int CreateDirectory(string path)
    {
        return -1;
    }

    public override void DeleteDirectory(string path)
    {
    }

    public override void DeleteFile(string path)
    {
    }

    public void Open(String path, String pathUrl)
    {
        var outputDir = System.IO.Path.GetTempPath();
        if (!outputDir.EndsWith("/") && !path.EndsWith("\\"))
        {
            outputDir += "/";
        }

        outputDir += path.GetFile() + "_output/";
        if (Directory.Exists(outputDir))
        {
            Directory.Delete(outputDir, true);
        }
        ZipFile.ExtractToDirectory(path, outputDir);

        Path = outputDir;
        Path = Path.Replace("\\/", "/");
        Path = Path.Replace("/\\", "/");
        Path = Path.Replace("\\", "/");
        PathUrl = pathUrl;
        AltPath = outputDir.Replace("/", "\\");
        AltPath2 = outputDir.Replace("\\", "/");
    }

    public override string GetFilePath(string path)
    {

        if (path.StartsWith(PathUrl))
        {
            path = path.Replace(PathUrl, Path);
            if (path == null)
            {
                throw new Exception("Path Conversion Error");
            }
        }
        else if (path.StartsWith("./"))
        {
            path = path.Replace("./", Path);
            if (path == null)
            {
                throw new Exception("Path Conversion Error");
            }
        }

        if (path.Contains("\\/"))
        {
            path = path.Replace("\\/", "/");
            path = path.Replace("\\", "/");
        }

        return path;
    }

    public override string GetFileUrl(string path){
        path = path.Replace(Path, PathUrl);
        path = path.Replace(AltPath, PathUrl);
        path = path.Replace(AltPath2, PathUrl);
        return path;
    }
}
