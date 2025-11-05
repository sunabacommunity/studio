using Godot;

namespace Sunaba.Engine;

public partial class PlatformService: Node
{
	public string PlatformName = "Sunaba Demo";

	public int DeviceType
	{
		get
		{
			if (OS.GetName() == "Windows" || OS.GetName() == "macOS" || OS.GetName() == "Linux")
				return 0;
			else if (OS.GetName() == "iOS" || OS.GetName() == "Android")
				return 1;
			else if (OS.GetName() == "Web")
				return 2;
			else if (OS.GetName() == "visionOS")
				return 3;
			else
				return -1;
		}
	}
	public string OsName => OS.GetName();

	public bool hasFeature(string feature)
	{
		return OS.HasFeature(feature);
	}
}
