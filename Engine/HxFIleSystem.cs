using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using FileAccess = System.IO.FileAccess;
#if !GODOT_WINDOWS
using Mono.Unix;
using Mono.Unix.Native;
#else
using System.Runtime.InteropServices;
#endif

namespace Sunaba.Engine;

public partial class HxFIleSystem: RefCounted
{
#if GODOT_WINDOWS
	[StructLayout(LayoutKind.Sequential)]
	struct BY_HANDLE_FILE_INFORMATION
	{
		public uint FileAttributes;
		public System.Runtime.InteropServices.ComTypes.FILETIME CreationTime;
		public System.Runtime.InteropServices.ComTypes.FILETIME LastAccessTime;
		public System.Runtime.InteropServices.ComTypes.FILETIME LastWriteTime;
		public uint VolumeSerialNumber;
		public uint FileSizeHigh;
		public uint FileSizeLow;
		public uint NumberOfLinks;
		public uint FileIndexHigh;
		public uint FileIndexLow;
	}


	[DllImport("kernel32.dll", SetLastError = true)]
	static extern bool GetFileInformationByHandle(IntPtr hFile, out BY_HANDLE_FILE_INFORMATION lpFileInformation);
#endif

	HxFIleSystem() {}

	public bool Exists(string path)
	{
		if (File.Exists(path))
			return true;
		else if (Directory.Exists(path))
			return true;
		else
			return false;
	}

	public Variant Stat(string path)
	{
		try
		{
			return FileStat(path);
		}
		catch (Exception e)
		{
			return e.Message;
		}
	}

	HxFileStat FileStat(string path)
	{
		FileInfo fileInfo = new FileInfo(path);
		HxFileStat fileStat = new();
		fileStat.Size = (long)fileInfo.Length;
		fileStat.MTime = HxDate.FromDateTime(fileInfo.LastWriteTime);
		fileStat.CTime = HxDate.FromDateTime(fileInfo.CreationTime);
		fileStat.ATime = HxDate.FromDateTime(fileInfo.LastAccessTime);
#if !GODOT_WINDOWS
		Stat unixStat;
		Syscall.stat(path, out unixStat);
		fileStat.Uid = (long)unixStat.st_uid;
		fileStat.Gid = (long)unixStat.st_gid;
		fileStat.Mode = (long)unixStat.st_mode;
		fileStat.Dev = (long)unixStat.st_dev;
		fileStat.NLink  = (long)unixStat.st_nlink;
		fileStat.Ino = (long)unixStat.st_ino;
		fileStat.RDev  = (long)unixStat.st_rdev;
#else
		using var file = File.Open(path, FileMode.Open, FileAccess.Read,  FileShare.ReadWrite);
		if (!GetFileInformationByHandle(file.SafeFileHandle.DangerousGetHandle(), out var information))
		{
			ulong fileIndex = ((ulong)information.FileIndexHigh << 32) + information.FileIndexLow;
			ulong fileSize = ((ulong)information.FileSizeHigh << 32) + information.FileSizeLow;

			fileStat.Uid = 0;
			fileStat.Gid = 0;
			fileStat.Mode = (long)information.FileAttributes;
			fileStat.Dev = information.VolumeSerialNumber;
			fileStat.NLink = information.NumberOfLinks;
			fileStat.Ino = (long)fileIndex;
			fileStat.RDev = 0;
		}
#endif

		return fileStat;
	}

	public static string FullPath(string relPath)
	{
		return Path.GetFullPath(relPath);
	}

	public static string AbsolutePath(string relPath)
	{
		if (relPath.IsAbsolutePath())
			return relPath;
		var cwd = Directory.GetCurrentDirectory();
		if (String.IsNullOrEmpty(cwd))
			return relPath;
		return Path.Combine(cwd, relPath);
	}

	public string[] ReadDirectory(string path)
	{
		List<string> dirArray = new();
		var directories = Directory.GetDirectories(path);
		foreach (var directory in directories)
		{
			dirArray.Add(directory);
			var subDirArray = ReadDirectory(directory).ToList();
			dirArray.AddRange(subDirArray);
		}

		var files = Directory.GetFiles(path);

		foreach (var file in files)
		{
			dirArray.Add(file);
		}

		return dirArray.ToArray();
	}

	public bool IsDirectory(string path)
	{
		return Directory.Exists(path);
	}

	public void DeleteDirectory(string path)
	{
		Directory.Delete(path);
	}

	public int CreateDirectory(string path)
	{
		return Directory.CreateDirectory(path).GetHashCode();
	}
}
