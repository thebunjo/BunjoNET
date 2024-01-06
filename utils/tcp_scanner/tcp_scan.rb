require 'socket'

class BunjoScanTCP
  def initialize host, timeout
    @host = host
    @timeout = timeout
  end

  def tcp_scan tcp_port
    tcp_socket = Socket.new Socket::AF_INET, Socket::SOCK_STREAM, 0

    begin
      tcp_socket_addr = Socket.sockaddr_in tcp_port, @host
    rescue SocketError => socket_addr_error
      $stdout.puts socket_addr_error.message
      tcp_socket.close
      return
    end

    begin
      tcp_socket.connect_nonblock tcp_socket_addr
      $stdout.puts "#{tcp_port}/tcp open".colorize :green
    rescue IO::WaitWritable
      IO.select nil, [tcp_socket], nil, @timeout
      retry
    rescue Errno::EISCONN
      $stdout.puts "#{tcp_port}/tcp open".colorize :green
    rescue Errno::ECONNREFUSED
      # Ignored
    rescue Errno::ETIMEDOUT
      # Ignored
    rescue Errno::EHOSTUNREACH
      # Ignored
    rescue Errno::ENETUNREACH
      # Ignored
    rescue Errno::EINVAL
      # Ignored
    rescue Exception
      # Ignored
    rescue Interrupt
      $stderr.puts "Program closed by user.".colorize :red
    ensure
      tcp_socket.close unless tcp_socket.closed?
    end
  end
end