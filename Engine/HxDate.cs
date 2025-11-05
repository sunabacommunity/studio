using System;
using Godot;

namespace Sunaba.Engine;

public partial class HxDate: RefCounted
{
	public int Year;
	public int Month;
	public int Day;
	public int Hour;
	public int Min;
	public int Sec;

	public static HxDate FromDateTime(DateTime dateTime)
	{
		var date = new HxDate();
		date.Year = dateTime.Year;
		date.Month = dateTime.Month;
		date.Day = dateTime.Day;
		date.Hour = dateTime.Hour;
		date.Min = dateTime.Minute;
		date.Sec = dateTime.Second;
		return date;
	}
}
