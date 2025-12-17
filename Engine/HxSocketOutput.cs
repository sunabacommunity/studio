using System;
using System.Net.Sockets;
using Godot;

namespace Sunaba.Engine;

public partial class HxSocketOutput: RefCounted
{
    private Socket _socket;
    
    public string Msg;
    
    public HxSocketOutput(Socket socket)
    {
        _socket = socket;
    }
    
    public int WriteByte(byte b)
    {
        try
        {
            _socket.Send(new byte[] { b }, 0, 1, SocketFlags.None);
            return 0;
        }
        catch (SocketException socketException)
        {
            Msg = socketException.Message;
            return -1;
        }
    }
    
    public int WriteBytes(byte[] s, int pos, int len) 
    {
        try
        {
            _socket.Send(s, pos, len, SocketFlags.None);
            return 0;
        }
        catch (SocketException socketException)
        {
            Msg = socketException.Message;
            return -1;
        }
    }
}