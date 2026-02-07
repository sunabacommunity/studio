using System;
using System.Linq;
using Godot;
using Godot.Collections;

namespace Sunaba.Engine;

[GlobalClass]
public partial class ZipIo : IoInterface
{
    private ZipReader _zip = new ZipReader();
    ZipIo() {}
    
    public Error Open(string path, string pathUrl)
    {
        PathUrl = pathUrl;
        if (path.EndsWith(".snb") || path.EndsWith(".slib") || path.EndsWith(".zip"))
        {
            var error = _zip.Open(path);
            var files = _zip.GetFiles();
            return error;
        }
        else
        {
            return Error.FileUnrecognized;
        }
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
        return path;
    }

    public override string LoadText(string assetPath)
    {
        if (!assetPath.Contains(PathUrl))
        {
            return null;
        }
        var path = GetFilePath(assetPath);
        if (!_zip.GetFiles().Contains(path))
        {
            return null;
        }
        return base.LoadText(assetPath);
    }

    public override byte[] LoadBytes(string assetPath)
    {
        if (!assetPath.Contains(PathUrl))
        {
            return null;
        }
        var path = GetFilePath(assetPath);
        if (!_zip.GetFiles().Contains(path))
        {
            return null;
        }
        return _zip.ReadFile(path);
    }

    public override bool DirectoryExists(string path)
    {
        var path2 = GetFilePath(path);
        foreach (var file in _zip.GetFiles())
        {
            if (file.EndsWith("/"))
            {
                if (file == path2)
                {
                    return true;
                }
            }
        }
        return false;
    }

    public override Array<string> GetFileList(string path, string extension = "", bool recursive = true)
    {
        var fileList = new Array<string>();
        var files = _zip.GetFiles();
        var path2 = GetFilePath(path);
        if (!path2.EndsWith("/"))
            path2 += "/";
        if (extension != "" && extension != "/")
        {
            foreach (var file in files)
            {
                var filePath = PathUrl + file;
                if (file.StartsWith(path2) && file.EndsWith(extension) && !file.Replace(path2, "").Contains("/"))
                {                    
                    fileList.Add(filePath);
                }
            }

            if (recursive)
            {
                var subDirs = GetFileList(path, "/", false);
                foreach (var subDir in subDirs)
                {
                    var subDirFiles = GetFileList(subDir, extension);
                    foreach (var subDirFile in subDirFiles)
                    {
                        if (!fileList.Contains(subDirFile))
                        {
                            fileList.Add(subDirFile);
                        }
                    }
                }
            }
        }
        else if (extension == "/")
        {
            foreach (var file in files)
            {
                var filePath = PathUrl + file;
                if (file.StartsWith(path2) && file.EndsWith("/") && !file.Replace(path2, "").Contains("/"))
                {
                    fileList.Add(filePath);
                }
                else
                {
                    var baseDir = file.GetBaseDir();
                    var dirPath = PathUrl + baseDir + "/";
                    if (baseDir.StartsWith(path2))
                    {
                        if (!baseDir.Replace(path2, "").Contains("/"))
                        {
                            if (!fileList.Contains(dirPath))
                            {
                                fileList.Add(dirPath);
                            }
                        }
                    }
                }

            }
            if (recursive)
            {
                var subDirs = GetFileList(path, "/", false);
                foreach (var subDir in subDirs)
                {
                    var subDirFiles = GetFileList(subDir, "/");
                    foreach (var subDirFile in subDirFiles)
                    {
                        if (!fileList.Contains(subDirFile))
                        {
                            fileList.Add(subDirFile);
                        }
                    }
                }
            }
        }
        else
        {
            foreach (var file in files)
            {
                var filePath = PathUrl + file;
                if (file.StartsWith(path2))
                {
                    if (!file.Replace(path2, "").Contains("/"))
                    {
                        fileList.Add(filePath);
                    }
                }
            }
            if (recursive)
            {
                var subDirs = GetFileList(path, "/", false);
                foreach (var subDir in subDirs)
                {
                    var subDirFiles = GetFileList(subDir);
                    foreach (var subDirFile in subDirFiles)
                    {
                        if (!fileList.Contains(subDirFile))
                        {
                            fileList.Add(subDirFile);
                        } 
                    }
                }
            }
        }
        return fileList;
    }
}