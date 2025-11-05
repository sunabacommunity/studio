using Godot;

namespace Sunaba.Engine;

public partial class HxFileStat: RefCounted
{
	public long Gid;
	public long Uid;
	public HxDate ATime;
	public HxDate MTime;
	public HxDate CTime;
	public long Size;
	public long Dev;
	public long Ino;
	public long NLink;
	public long RDev;
	public long Mode;
}

