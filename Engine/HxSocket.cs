using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using Godot;
using Godot.Collections;
using Array = Godot.Collections.Array;

namespace Sunaba.Engine;

public partial class HxSocket : RefCounted
{
    protected SocketWrapper _socket;

    public HxSocketInput Input;
    public HxSocketOutput Output;

    private float? _timeout = null;
    private bool _blocking = false;
    
    public string Msg;

    public HxSocket()
    {
    }

    public void Close()
    {
        if (_socket != null)
        {
            _socket.Close();
        }
    }

    public int Connect(HxNetHost host, int port)
    {
        var res = SocketWrapper.Connect(host.Host, port);
        if (res.Message != null)
        {
            Msg = res.Message;
            return -1;
        }
        Input = new HxSocketInput(res.Value._socket);
        Output = new HxSocketOutput(res.Value._socket);
        _socket = res.Value;
        if (_timeout.HasValue)
        {
            _socket.SetTimeout(_timeout.Value);
        }
        return 0;
    }

    public int Listen(int connections)
    {
        try
        {
            var res = SocketWrapper.Tcp();
            if (res.Message != null)
            {
                Msg = res.Message;
                return -1;
            }

            res.Value.Listen(connections);
            _socket = res.Value;
            if (_timeout.HasValue)
            {
                _socket.SetTimeout(_timeout.Value);
            }

            return 0;
        }
        catch (SocketException se)
        {
            Msg = se.Message;
            return -1;
        }
    }

    public void Shutdown(bool read, bool write)
    {
        TcpClient tcpClient = new TcpClient(_socket._socket);
        switch (read, write)
        {
            case (true, true):
                tcpClient.Shutdown(ShutdownMode.Both);
                break;
            case (true, false):
                tcpClient.Shutdown(ShutdownMode.Receive);
                break;
            case (false, true):
                tcpClient.Shutdown(ShutdownMode.Send);
                break;
            default:
                break;
        }
    }

    public int Bind(HxNetHost host, int port)
    {
        var res = SocketWrapper.Bind(host.Host, port);
        if (res.Message != null)
        {
            Msg = res.Message;
            return -1;
        }
        _socket = res.Value;
        return 0;
    }

    public Dictionary Accept()
    {
        var dict = new Dictionary();
        dict["message"] = "";
        TcpServer tcpServer = new TcpServer(_socket._socket);
        if (tcpServer == null)
        {
            dict["message"] = "Socket is not a TcpServer.";
            return dict;
        }
        
        var res = tcpServer.Accept();
        if (res.Message != null)
        {
            dict["message"] = res.Message;
            return dict;
        }
        var sock = new HxSocket();
        sock._socket = res.Value;
        sock.Input = new HxSocketInput(res.Value._socket);
        sock.Output = new HxSocketOutput(res.Value._socket);
        dict["result"] = sock;
        return dict;
    }

    public Dictionary Peer()
    {
        TcpClient client =  new TcpClient(_socket._socket);
        var res = client.GetPeerName();
        var host = new Dictionary();
        host["name"] = res.Address;
        var dict = new Dictionary();
        dict["host"] = host;
        dict["port"] = int.Parse(res.Port);
        return dict;
    }

    public Dictionary Host()
    {
        TcpServer server = new TcpServer(_socket._socket);
        var res = server.GetSockName();
        var host = new Dictionary();
        host["name"] = res.Address;
        var dict = new Dictionary();
        dict["host"] = host;
        dict["port"] = int.Parse(res.Port);
        return dict;        
    }

    public void SetTimeout(float timeout)
    {
        _timeout = timeout;
        if (_socket != null)
        {
            _socket.SetTimeout(timeout);
        }
    }

    public void SetBlocking(bool b)
    {
        _blocking = b;
    }

    public void SetFastSend(bool b)
    {
        if (_socket != null)
        {
            TcpClient client = new TcpClient(_socket._socket);
            client.SetOption(SocketOption.TcpNoDelay, true);
        }
    }

    public Dictionary Select(Array read, Array write, Array others, float? timeout = null)
    {
        var readTbl = read.ToList().Select(r => r.As<HxSocket>()._socket).ToList();
        var writeTbl = write.ToList().Select(r => r.As<HxSocket>()._socket).ToList();
        var res = SocketWrapper.Select(readTbl, writeTbl, timeout);

        var convertSocket = (SocketWrapper x) =>
        {
            var sock = new HxSocket();
            sock.Input = new HxSocketInput(x._socket);
            sock.Output = new HxSocketOutput(x._socket);
            return sock;
        };

        var readArr = res.Read == null ? new Array() : new Array(res.Read.Select(convertSocket).ToArray());
        
        var writeArr = res.Write == null ? new Array() : new Array(res.Write.Select(convertSocket).ToArray());

        var dict = new Dictionary();
        dict["read"] = readArr;
        dict["write"] = writeArr;
        dict["others"] = new Array();
        return dict;
    }
}