using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;

namespace Sunaba.Engine
{
    public class SocketWrapper
    {
        public static bool _DEBUG { get; set; }
        public static string _VERSION { get; set; } = "1.0.0";

        internal Socket _socket;
        protected double? _timeout = null;

        protected SocketWrapper() { }

        protected SocketWrapper(Socket socket)
        {
            _socket = socket;
        }

        public static Result<TcpMaster> Tcp()
        {
            try
            {
                var socket = new Socket(
                    AddressFamily.InterNetwork,
                    SocketType.Stream,
                    ProtocolType.Tcp
                );
                return Result<TcpMaster>.Success(new TcpMaster(socket));
            }
            catch (Exception ex)
            {
                return Result<TcpMaster>.Failure(ex.Message);
            }
        }

        public static Result<TcpServer> Bind(
            string address,
            int port,
            int backlog = 32
        )
        {
            try
            {
                var socket = new Socket(
                    AddressFamily.InterNetwork,
                    SocketType.Stream,
                    ProtocolType.Tcp
                );
                
                // Try to parse as IP address first, if it fails, resolve as hostname
                IPAddress ipAddress;
                if (!IPAddress.TryParse(address, out ipAddress))
                {
                    var addresses = Dns.GetHostAddresses(address);
                    if (addresses.Length == 0)
                        return Result<TcpServer>.Failure("Unable to resolve host: " + address);
                    ipAddress = addresses[0];
                }
                
                var endpoint = new IPEndPoint(ipAddress, port);

                socket.Bind(endpoint);
                socket.Listen(backlog);

                return Result<TcpServer>.Success(new TcpServer(socket));
            }
            catch (Exception ex)
            {
                return Result<TcpServer>.Failure(ex.Message);
            }
        }

        public static Result<TcpClient> Connect(
            string address,
            int port,
            string locaddr = null,
            int? locport = null
        )
        {
            try
            {
                var socket = new Socket(
                    AddressFamily.InterNetwork,
                    SocketType.Stream,
                    ProtocolType.Tcp
                );

                if (locaddr != null && locport.HasValue)
                {
                    IPAddress localIpAddress;
                    if (!IPAddress.TryParse(locaddr, out localIpAddress))
                    {
                        var addresses = Dns.GetHostAddresses(locaddr);
                        if (addresses.Length == 0)
                            return Result<TcpClient>.Failure("Unable to resolve local host: " + locaddr);
                        localIpAddress = addresses[0];
                    }
                    
                    var localEndpoint = new IPEndPoint(localIpAddress, locport.Value);
                    socket.Bind(localEndpoint);
                }

                // Try to parse as IP address first, if it fails, resolve as hostname
                IPAddress remoteIpAddress;
                if (!IPAddress.TryParse(address, out remoteIpAddress))
                {
                    var addresses = Dns.GetHostAddresses(address);
                    if (addresses.Length == 0)
                        return Result<TcpClient>.Failure("Unable to resolve host: " + address);
                    remoteIpAddress = addresses[0];
                }

                var remoteEndpoint = new IPEndPoint(remoteIpAddress, port);
                socket.Connect(remoteEndpoint);

                return Result<TcpClient>.Success(new TcpClient(socket));
            }
            catch (Exception ex)
            {
                return Result<TcpClient>.Failure(ex.Message);
            }
        }

        public static double GetTime()
        {
            return DateTime.UtcNow.Subtract(
                new DateTime(1970, 1, 1)
            ).TotalSeconds;
        }

        public static SelectResult Select(
            List<SocketWrapper> recvt,
            List<SocketWrapper> sendt,
            double? timeout = null
        )
        {
            var checkRead = recvt?.Select(s => s._socket).ToList() 
                ?? new List<Socket>();
            var checkWrite = sendt?.Select(s => s._socket).ToList() 
                ?? new List<Socket>();
            var checkError = new List<Socket>();

            int microSeconds = timeout.HasValue 
                ? (int)(timeout.Value * 1_000_000) 
                : -1;

            Socket.Select(checkRead, checkWrite, checkError, microSeconds);

            var convertSocket = new Func<Socket, SocketWrapper>(s =>
            {
                if (recvt != null)
                {
                    var wrapper = recvt.FirstOrDefault(w => w._socket == s);
                    if (wrapper != null) return wrapper;
                }
                if (sendt != null)
                {
                    var wrapper = sendt.FirstOrDefault(w => w._socket == s);
                    if (wrapper != null) return wrapper;
                }
                return null;
            });

            return new SelectResult
            {
                Read = checkRead.Select(convertSocket)
                    .Where(w => w != null).ToList(),
                Write = checkWrite.Select(convertSocket)
                    .Where(w => w != null).ToList()
            };
        }

        public void Close()
        {
            _socket?.Close();
            _socket?.Dispose();
        }

        public AddrInfo GetSockName()
        {
            var endpoint = _socket.LocalEndPoint as IPEndPoint;
            return new AddrInfo
            {
                Address = endpoint.Address.ToString(),
                Port = endpoint.Port.ToString()
            };
        }

        public void SetTimeout(double value, TimeoutMode mode = TimeoutMode.Block)
        {
            _timeout = value;
            int milliseconds = (int)(value * 1000);

            if (_socket == null) return;

            switch (mode)
            {
                case TimeoutMode.Block:
                    _socket.ReceiveTimeout = milliseconds;
                    _socket.SendTimeout = milliseconds;
                    break;
                case TimeoutMode.Receive:
                    _socket.ReceiveTimeout = milliseconds;
                    break;
                case TimeoutMode.Send:
                    _socket.SendTimeout = milliseconds;
                    break;
            }
        }
    }

    public class TcpMaster : SocketWrapper
    {
        public TcpMaster(Socket socket) : base(socket) { }

        public void Listen(int connections)
        {
            _socket.Listen(connections);
        }
    }

    public class TcpServer : SocketWrapper
    {
        public TcpServer(Socket socket) : base(socket) { }

        public Result<TcpClient> Accept()
        {
            try
            {
                var clientSocket = _socket.Accept();
                var client = new TcpClient(clientSocket);
                if (_timeout.HasValue)
                {
                    client.SetTimeout(_timeout.Value);
                }
                return Result<TcpClient>.Success(client);
            }
            catch (Exception ex)
            {
                return Result<TcpClient>.Failure(ex.Message);
            }
        }
    }

    public class TcpClient : SocketWrapper
    {
        public TcpClient(Socket socket) : base(socket) { }

        public AddrInfo GetPeerName()
        {
            var endpoint = _socket.RemoteEndPoint as IPEndPoint;
            return new AddrInfo
            {
                Address = endpoint.Address.ToString(),
                Port = endpoint.Port.ToString()
            };
        }

        public void Shutdown(ShutdownMode mode)
        {
            switch (mode)
            {
                case ShutdownMode.Receive:
                    _socket.Shutdown(SocketShutdown.Receive);
                    break;
                case ShutdownMode.Send:
                    _socket.Shutdown(SocketShutdown.Send);
                    break;
                case ShutdownMode.Both:
                    _socket.Shutdown(SocketShutdown.Both);
                    break;
            }
        }

        public void SetOption(SocketOption option, bool value)
        {
            if (option == SocketOption.TcpNoDelay)
            {
                _socket.NoDelay = value;
            }
        }
    }

    public class Result<T>
    {
        public T Value { get; }
        public string Message { get; }

        private Result(T value, string message)
        {
            Value = value;
            Message = message;
        }

        public static Result<T> Success(T value) => 
            new Result<T>(value, null);
        
        public static Result<T> Failure(string error) => 
            new Result<T>(default, error);
    }

    public struct AddrInfo
    {
        public string Address { get; set; }
        public string Port { get; set; }
    }

    public struct SelectResult
    {
        public List<SocketWrapper> Read { get; set; }
        public List<SocketWrapper> Write { get; set; }
    }

    public enum TimeoutMode
    {
        Block,
        Receive,
        Send
    }

    public enum ShutdownMode
    {
        Receive,
        Send,
        Both
    }

    public enum SocketOption
    {
        TcpNoDelay
    }
}