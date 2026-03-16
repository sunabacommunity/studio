using System;
using System.IO;
using System.Text;
using DiscUtils.Iso9660;
using Godot;
using Godot.Collections;
using Array = Godot.Collections.Array;

namespace Sunaba.Engine;

[GlobalClass]
public partial class ReadOnlyIo : IoInterface
{
    private CDReader _reader;

    ReadOnlyIo() 
    {
    }

    public void Open(string path, string pathUrl)
    {
        PathUrl = pathUrl;
        var isoStream = File.Open(path, FileMode.Open);
        _reader = new(isoStream, true);
    }
    
    public override string GetFilePath(string path)
    {
        if (path.StartsWith(PathUrl))
        {
            path = path.Replace(PathUrl, "");
            if (path == null)
            {
                throw new Exception("Path Conversion Error");
            }
        }
        else if (path.StartsWith("./"))
        {
            path = path.Replace("./", "");
            if (path == null)
            {
                throw new Exception("Path Conversion Error");
            }
        }
        if (path.Contains("\\"))
        {
            path = path.Replace("\\/", "/");
            path = path.Replace("\\", "/");
        }
        if (path.Contains("/"))
        {
            path = path.Replace("/", "\\");
        }
        path = path.Replace("\\", "/");
        path = path.Replace("/", "\\");
        return path;
    }

    public override byte[] LoadBytes(string assetPath)
    {
        var filePath = GetFilePath(assetPath);
        if (_reader.FileExists(filePath))
        {
            var bytes = _reader.ReadAllBytes(filePath);
            return bytes;
        }
        else
        {
            return null;
        }
    }

    public override string LoadText(string assetPath)
    {
        var bytes = LoadBytes(assetPath);
        if (bytes == null) return String.Empty;
        else
        {
            return Encoding.Unicode.GetString(bytes);
        }
    }

    public override bool DirectoryExists(string path)
    {
        var dirPath = GetFilePath(path);
        return _reader.DirectoryExists(dirPath);
    }

    public override Array<string> GetFileList(string path, string extension = "", bool recursive = true)
    {
        path = GetFilePath(path);

        var searchOption = SearchOption.TopDirectoryOnly;
        if (recursive)
        {
            searchOption = SearchOption.AllDirectories;
        }

        Array<string> list = new();
        if (!_reader.DirectoryExists(path)) {}
        else switch (extension)
        {
            case "/":
            {
                var directories = _reader.GetDirectories(path, "*.*", searchOption);
                foreach (var dir in directories)       
                {
                    list.Add(PathUrl + dir.Replace("\\", "/"));
                }

                break;
            }
            case "":
            {
                var dirs = GetFileList(path, "/", recursive);
                foreach (var dir in dirs)
                {
                    list.Add(dir);
                    var realDir = GetFilePath(dir);
                    var filesOfDir = _reader.GetFiles(realDir, "*.*", searchOption);
                    foreach (var file in filesOfDir)
                    {
                        list.Add(PathUrl + file.Replace("\\", "/"));
                    }
                }

                break;
            }
            default:
            {
                if (!extension.StartsWith("*.") && !extension.StartsWith("."))
                {
                    extension = "*." + extension;
                }
                else if (!extension.StartsWith("*.") && extension.StartsWith("."))
                {
                    extension = "*" + extension;
                }
                var files = _reader.GetFiles(path, extension, searchOption);
                foreach (var file in files)
                {
                    list.Add(PathUrl + file.Replace("\\", "/"));
                }
                break;
            }
        }

        return list;
    }
}