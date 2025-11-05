using System;
using System.Collections.Generic;
using System.IO;
using Godot;

namespace Sunaba.Engine
{
	[GlobalClass]
    public partial class FileSystemIo : SystemIoBase
    {
        public String Path;
        public String AltPath;
        public String AltPath2;

        public FileSystemIo()
        {
        }

        public FileSystemIo(String path, String pathUrl)
        {
	        if (!path.EndsWith("/") && !path.EndsWith("\\"))
	        {
		        path += "/";
	        }

	        Path = path;
	        PathUrl = pathUrl;
	        AltPath = path.Replace("/", "\\");
	        AltPath2 = path.Replace("\\", "/");
        }

        public void Open(String path, String pathUrl)
        {
	        if (!path.EndsWith("/") && !path.EndsWith("\\"))
	        {
		        path += "/";
	        }

	        Path = path;
	        PathUrl = pathUrl;
	        AltPath = path.Replace("/", "\\");
	        AltPath2 = path.Replace("\\", "/");
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
            return path;
        }
    }
}
