using Godot;
using System.Net;
using System.Net.Sockets;
using System;

namespace Sunaba.Engine;

public partial class HxNetHost: RefCounted
{
    public string Ip;
    public string Host;

    public HxNetHost() {}

    public HxNetHost(string name)
    {
        Host = name;
        
        // Check if name is already an IP address
        IPAddress ipAddress;
        if (IPAddress.TryParse(name, out ipAddress))
        {
            Ip = name;
        }
        else
        {
            // Resolve hostname to IP address
            try
            {
                var addresses = Dns.GetHostAddresses(name);
                if (addresses.Length == 0)
                    throw new Exception("Unrecognized node name");
                    
                Ip = addresses[0].ToString();
                
                // Handle IPv6 loopback (convert ::1 to 127.0.0.0 for consistency with Lua version)
                if (Ip == "::1")
                    Ip = "127.0.0.0";
            }
            catch (Exception ex)
            {
                throw new Exception("Unrecognized node name: " + ex.Message);
            }
        }
    }

    public string Msg;

    public Variant GetAddrInfo(string name)
    {
        try
        {
            var addresses = Dns.GetHostAddressesAsync(name); // Use 'name' parameter
            addresses.Wait();

            if (addresses.Result.Length == 0)
                return new Variant(); // Handle no results

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
        catch (Exception e)
        {
            Msg = e.Message;
            return -1;
        }
    }

    public string ip;

    public string host;
    
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