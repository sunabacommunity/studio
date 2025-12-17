using Godot;
using System.Net;
using System.Net.Sockets;

namespace Sunaba.Engine;

public partial class HxNetHost: RefCounted
{
    public HxNetHost() {}

    public HxDnsAddrInfo GetAddrInfo(string name)
    {
        var addresses = Dns.GetHostAddressesAsync(name); // Use 'name' parameter
        addresses.Wait();
        
        if (addresses.Result.Length == 0)
            return null; // Handle no results
            
        var addr = addresses.Result[0];
        var info = new HxDnsAddrInfo
        {
            Ip = addr.ToString(),
            Addr = addr.ToString(),
            Port = 0,
            Family = addr.AddressFamily == AddressFamily.InterNetwork ? "IPv4" : "IPv6",
            Socktype = "Stream"
        };
        
        return info;
    }

    public string Ip;

    public string Host;
    
    public string Reverse()
    {
        var ipAddress = IPAddress.Parse(Ip);
        var hostEntry = Dns.GetHostEntry(ipAddress);
        return hostEntry.HostName;
    }
    
    public string Localhost()
    {
        return Dns.GetHostName();
    }
}