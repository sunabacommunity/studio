using System.Collections.Generic;
using System.IO;
using Godot.Collections;
using Godot;

namespace Sunaba.Engine
{
	[GlobalClass]
    public partial class IoManager : IoInterface
    {
        public List<IoInterface> IoInterfaces { get; } = new List<IoInterface>();

        public IoManager()
        {
            PathUrl = "ioInterfaceMulti://";
        }

        public override string GetFilePath(string path)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                var file = ioInterface.GetFilePath(path);
                if (file != null)
                {
                    return file;
                }
            }

            return null;
        }

        public string GetFileUrl(string path, string pathUrl)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                if (ioInterface.PathUrl == pathUrl)
                {
                    if (ioInterface is SystemIoBase fileSys)
                    {
                        return fileSys.GetFilePath(path);
                    }
                }
            }

            return pathUrl + path;
        }

        public void Register(IoInterface ioInterface)
        {
            if (ioInterface is IoManager)
            {
                throw new System.Exception("Cannot register IoManager");
            }
            IoInterfaces.Add(ioInterface);
        }

        public void RegisterPath(string path, string pathUrl)
        {
            Register(new FileSystemIo(path, pathUrl));
        }

        public void Unregister(IoInterface ioInterface)
        {
            IoInterfaces.Remove(ioInterface);
        }

        public override byte[] LoadBytes(string assetPath)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                var file = ioInterface.LoadBytes(assetPath);
                if (file != null)
                {
                    return file;
                }
            }

            return null;
        }

        public override void SaveBytes(string assetPath, byte[] bytes)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                if (assetPath.StartsWith(ioInterface.PathUrl))
                {
                    ioInterface.SaveBytes(assetPath, bytes);
                    return;
                }
            }
        }

        public override string LoadText(string assetPath)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                var file = ioInterface.LoadText(assetPath);
                if (file != null)
                {
                    return file;
                }
            }

            return null;
        }

        public override void SaveText(string assetPath, string text)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                if (assetPath.StartsWith(ioInterface.PathUrl))
                {
                    ioInterface.SaveText(assetPath, text);
                    return;
                }
            }
        }

        public override int CreateDirectory(string path)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                if (path.StartsWith(ioInterface.PathUrl))
                {
                    return ioInterface.CreateDirectory(path);
                }
            }

            return 1;
        }

        public override Array<string> GetFileList(string path, string extension = "", bool recursive = true)
        {
	        Array<string> fileList = new Array<string>();

            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                if (path.StartsWith(ioInterface.PathUrl))
                {
                    var ioInterfaceFileList = ioInterface.GetFileList(path, extension, recursive);

                    foreach(string filePath in ioInterfaceFileList)
                    {
                        if (path == PathUrl)
                        {
                            fileList.Add(filePath);
                        }
                        else if (filePath.StartsWith(path))
                        {
                            fileList.Add(filePath);
                        }
                    }
                }
            }

            return fileList;
        }


        public override void DeleteFile(string path)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                if (path.StartsWith(ioInterface.PathUrl))
                {
                    ioInterface.DeleteFile(path);
                    return;
                }
            }
        }

        public string GetFullPath(string path)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                if (path.StartsWith(ioInterface.PathUrl))
                {
                    if (ioInterface is SystemIoBase fileSys)
                    {
                        return fileSys.GetFilePath(path);
                    }
                }
            }

            return null;
        }

        public override bool DirectoryExists(string path)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                if (path.StartsWith(ioInterface.PathUrl))
                {
                    return ioInterface.DirectoryExists(path);
                }
            }

            return false;
        }

        public override void DeleteDirectory(string path)
        {
            for (int i = 0; i < IoInterfaces.Count; i++)
            {
                var ioInterface = IoInterfaces[i];
                if (path.StartsWith(ioInterface.PathUrl))
                {
                    ioInterface.DeleteDirectory(path);
                    return;
                }
            }
        }
    }
}
