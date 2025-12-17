using System.Net.Sockets;
using Godot;

namespace Sunaba.Engine;

public partial class HxSocketInput : RefCounted
{
    private Socket _socket;

    public string Msg;
    
    public HxSocketInput(Socket socket)
    {
        _socket = socket;
    }

    public int ReadByte()
    {
        Msg = "";
        try
        {
            byte[] buffer = new byte[1];
            int bytesRead = _socket.Receive(buffer, 0, 1, SocketFlags.None);
            if (bytesRead == 0)
            {
                return -1; // Indicate end of stream
            }
            return buffer[0];
        }
        catch (SocketException socketException)
        {
            Msg = socketException.Message;
            return -1;
        }
    }
    
    public int ReadBytes(byte[] s, int pos, int len)
    {
        Msg = "";
        try
        {
            return _socket.Receive(s, pos, len, SocketFlags.None);
        }
        catch (SocketException socketException)
        {
            Msg = socketException.Message;
            return -1;
        }
    }
}