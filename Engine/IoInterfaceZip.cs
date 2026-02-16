using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using Godot.Collections;
using Godot;
using System.Linq;

namespace Sunaba.Engine;

[GlobalClass]
public partial class IoInterfaceZip : IoInterface
{
	ZipArchive zipArchive;

	IoInterfaceZip()
	{
	}

	public void LoadFromPath(string path, string pathUrl)
	{
		PathUrl = pathUrl;
		if (path.EndsWith(".snb") || path.EndsWith(".slib") || path.EndsWith(".zip"))
		{
			zipArchive = ZipFile.OpenRead(path);
		}
		else
		{
			throw new Exception("Invalid Zip File");
		}
	}

	public void LoadFromBytes(byte[] buffer, string pathUrl)
	{
		PathUrl = pathUrl;
		MemoryStream ms = new MemoryStream(buffer);
		zipArchive = new ZipArchive(ms);
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

	public string SanitizePath(string path)
	{
		path = path.Replace("\\/", "\\");
		path = path.Replace("\\", "/");
		return path;
	}

	public override string LoadText(string assetPath)
	{
		string path = GetFilePath(assetPath);
		ZipArchiveEntry entry = zipArchive.GetEntry(path);
		if (entry == null)
		{
			return null;
		}
		using (StreamReader reader = new StreamReader(entry.Open()))
		{
			return reader.ReadToEnd();
		}
	}

	public override byte[] LoadBytes(string assetPath)
	{
		string path = GetFilePath(assetPath);
		ZipArchiveEntry entry = zipArchive.GetEntry(path);
		if (entry == null)
		{
			return null;
		}
		using (MemoryStream ms = new MemoryStream())
		{
			entry.Open().CopyTo(ms);
			return ms.ToArray();
		}
	}

	private Array<String> _getFiles()
	{
		var entries = zipArchive.Entries;
		Array<String> assets = [];
		foreach (var zipArchiveEntry in entries)
		{
			assets.Add(zipArchiveEntry.FullName);
		}

		return assets;
	}

	public override Array<string> GetFileList(string path, string extension = "", bool recursive = true)
	{
		var fileList = new Array<string>();
		var files = _getFiles();
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
	public override bool DirectoryExists(string path)
	{
		path = GetFilePath(path);
		foreach (var entry in zipArchive.Entries)
		{
			if (entry.FullName.StartsWith(path))
				return true;

		}

		return false;
	}
}
