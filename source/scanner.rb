require 'socket'

class BunjoScan
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
      $stderr.puts "Program closed.".colorize :red
    ensure
      tcp_socket.close unless tcp_socket.closed?
    end
  end

  def udp_scan udp_port
    udp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM, 0)

    begin
      udp_socket_addr = Socket.sockaddr_in(udp_port, @host)
    rescue SocketError => socket_addr_error
      $stdout.puts socket_addr_error.message
      udp_socket.close
      return
    end

    begin
      udp_socket.connect_nonblock udp_socket_addr
      $stdout.puts "#{udp_port}/udp open".colorize :green
    rescue IO::WaitWritable
      IO.select nil, [udp_socket], nil, @timeout
      retry
    rescue Errno::EISCONN
      $stdout.puts "#{udp_port}/udp open".colorize(:green)
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
      $stderr.puts "Program closed.".colorize :red
    ensure
      udp_socket.close unless udp_socket.closed?
    end
  end
end