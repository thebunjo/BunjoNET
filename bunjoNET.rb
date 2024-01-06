class BunjoNET
  def initialize
    require 'optparse'
    require 'colorize'

    @parameters = {
      help: false, host: nil,
      timeout: 1, threads: 5,
      tcp_all: false, udp_all: false,
      exclude_tcp: nil, exclude_udp: nil,
      script: nil,  script_class: nil,

      script_args: {
        host: nil,
        port: nil,
      }
    }

    parse_options

    $current_directory = File.expand_path File.dirname __FILE__
  end

  def banner
    banner_text =<<-'BANNER'
--------------------------------------    
.                    .   ..---..---.  
|              o     |\  ||      |    
|.-. .  . .--. . .-. | \ ||---   |    
|   )|  | |  | |(   )|  \||      |    
'`-' `--`-'  `-| `-' '   ''---'  '    
               ;                      
            `-'                       
--------------------------------------
    BANNER

    $stdout.puts banner_text.colorize :red
  end

  def parse_options
    begin
      OptionParser.new do |params|
        params.on "--host HOST", String, "Define the target host" do |host|
          @parameters[:host] = host
        end

        params.on "--threads THREADS", Integer, "Enter threads to parallel scan (default: 5)" do |threads|
          @parameters[:threads] = threads
        end

        params.on "--script", String, "Select scripts to use" do |script|
          if script.include? ","
            @parameters[:script] = script.split ","
          else
            case script
            when "Discover"
              @parameters[:script_class] = "Discover"
            when "Info"
              @parameters[:script_class] = "Info"
            else
              $stderr.puts "Error: Please enter valid scripts.".colorize :red
            end
          end
        end

        params.on "--script-args", String, "Define args to use on script attack" do |script_args|
          @parameters[:script_args] = script_args
        end

        params.on "--exclude-tcp EXCLUDE_TCP_PORTS", String, "Define tcp ports to skip on scan" do |exclude_tcp|
          if exclude_tcp.include? "-"
            @exclude_range_tcp = exclude_tcp.split "-"
            @exclude_tcp_range_used = true
            if @exclude_range_tcp[0].to_i < @exclude_range_tcp[1].to_i
              @parameters[:exclude_tcp] = (@exclude_range_tcp[0].to_i..@exclude_range_tcp[1].to_i).to_a
            elsif @exclude_range_tcp[0].to_i == @exclude_range_tcp[1].to_i
              @parameters[:exclude_tcp] = [@exclude_range_tcp[0].to_i]
            end
          elsif exclude_tcp.include? ","
            @parameters[:exclude_tcp] = exclude_tcp.split(",").map(&:to_i)
          else
            @parameters[:exclude_tcp] = [exclude_tcp.to_i]
          end
        end

        params.on "--exclude-udp EXCLUDE_UDP_PORTS", String, "Define udp ports to skip on scan" do |exclude_udp|
          if exclude_udp.include? "-"
            @exclude_range_udp = exclude_udp.split "-"
            @exclude_udp_range_used = true
            if @exclude_range_udp[0].to_i < @exclude_range_udp[1].to_i
              @parameters[:exclude_udp] = @exclude_range_udp[0]..@exclude_range_udp[1]
            elsif @exclude_range_udp[0].to_i == @exclude_range_udp[1].to_i
              @parameters[:exclude_udp] = [@exclude_range_udp[0].to_i]
            end
          elsif exclude_udp.include? ","
            @parameters[:exclude_udp] = exclude_udp.split ","
          else
            @parameters[:exclude_udp] = exclude_udp.to_i
          end
        end

        params.on "--tcp TCP_PORTS", "-tcp TCP_PORTS", String, "Define tcp ports to scan" do |tcp_ports|
          if tcp_ports.downcase.include? "all"
            @parameters[:tcp_ports] = 1..65535
          elsif tcp_ports.include? "-"
            tcp_range = tcp_ports.split "-"
            if tcp_range[0].to_i < tcp_range[1].to_i
              @parameters[:tcp_ports] = tcp_range[0]..tcp_range[1]
            elsif tcp_range[0].to_i == tcp_range[1].to_i
              @parameters[:tcp_ports] = [tcp_range[0].to_i]
            else
              $stderr.puts "Please enter valid port range for TCP.".colorize :red
            end
          elsif tcp_ports.include? ","
            @parameters[:tcp_ports] = tcp_ports.split ","
          else
            @parameters[:tcp_ports] = [tcp_ports.to_i]
          end
        end

        params.on "--output", "Enter file to save output" do |output|
          @parameters[:output] = output
        end

        params.on "--udp UDP_PORTS", String, "Define udp ports to scan" do |udp_ports|
          if udp_ports.downcase.include? "all"
            @parameters[:udp_ports] = 1..65535
          elsif udp_ports.include? "-"
            udp_range = udp_ports.split "-"
            if udp_range[0].to_i < udp_range[1].to_i
              @parameters[:udp_ports] = udp_range[0]..udp_range[1]
            elsif udp_range[0].to_i == udp_range[1].to_i
              @parameters[:udp_ports] = [udp_range[0].to_i]
            end
          elsif udp_ports.include? ","
            @parameters[:udp_ports] = udp_ports.split ","
          else
            @parameters[:udp_ports] = [udp_ports.to_i]
          end
        end

        params.on "--timeout TIMEOUT", Float, "Define udp ports to scan" do |timeout|
          if timeout >= 0
            @parameters[:timeout] = timeout.to_f
          else
            @parameters[:timeout] = 0
          end
        end

        params.on "--help", "-h", String, "Print help text" do
          @parameters[:help] = true
        end
      end.parse!

    rescue Exception => parser_error
      $stderr.puts "#{parser_error.class}:#{parser_error.message}".colorize :red
      exit 1
    end
  end

  def save_output

  end

  def valid_ports? ports
    valid_negative = ports.all? { |port| port.to_i >= 0 }
    valid_range = ports.all? { |port| port.to_i <= 65535 }

    unless valid_range
      $stderr.puts "Error: Ports must not be higher than 65535.\n".colorize :red
    end

    unless valid_negative
      $stderr.puts "Error: Ports must be non-negative integers.\n".colorize :red
    end

    valid_negative
    valid_range
  end

  def print_help
    puts
    help_text = <<-'HELP_TEXT'
HELP STAGE

    DEFINE TARGET
      --host HOST: Define the target host

    PORT SCANNING
      --tcp: TCP PORTS: Ports for TCP scanning      
      --tcp all: Scan all tcp ports
      --exclude-tcp PORTS: TCP ports to skip on scan
      
      --udp: UDP PORTS: Port for UDP scanning
      --udp all: Scan all udp ports
      --exclude-udp PORTS: UDP ports to skip on scan

      --banner: Use this for get the banners of the ports
      --exclude-banner TCP_PORT: Do not get banners for defined ports 

    TIMING
      --timeout TIMEOUT: Enter timeout time (default: 1)

    HELP
      --help: Prints this text message
    
    SCRIPTING
      --script SCRIPT: Select scripts to use
      --script-args SCRIPT: Define args to use on script attack
  
    MECHANISM
      --threads THREADS: Enter threads to parallel scan (default: 5)
    
    SAVE OUTPUT
      --output FILE: Enter file to save output 

    EXAMPLES
      bnjmap --host example.com --tcp 21,80,3306 --udp 53
      bnjmap --host example.com --tcp 80,3306 --timeout 0.5
    
    HELP_TEXT

    $stdout.puts help_text.colorize :light_white
  end

  def display_parameters
    def display_parameter key, label
      if @parameters[key].is_a? Array
        $stdout.puts "#{label}: #{@parameters[key].join ', '}"
                       .colorize :light_cyan if @parameters[key].any?
      else
        $stdout.puts "#{label}: #{@parameters[key]}"
                       .colorize :light_cyan if @parameters[key]
      end
    end

    unless @parameters[:host].nil?
      banner
      $stdout.puts "SCAN INFORMATIONS".colorize :light_white
      display_parameter :host, "Target Host"
      $stdout.puts

      display_parameter :tcp_ports, "TCP Ports"

      if @exclude_tcp_range_used
        $stdout.puts "Exclude TCP: #{@exclude_range_tcp[0]..@exclude_range_tcp[1]}".
          colorize :light_cyan unless @parameters[:exclude_tcp].nil?
      else
        $stdout.puts "Exclude TCP: #{@parameters[:exclude_tcp].join(",")}\n"
                       .colorize :light_cyan unless @parameters[:exclude_tcp].nil?
      end

      display_parameter :udp_ports, "UDP Ports"

      if @exclude_udp_range_used
        $stdout.puts "Exclude UDP: #{@exclude_range_udp[0]..@exclude_range_udp[1]}"
                       .colorize :light_cyan unless @parameters[:exclude_udp].nil?
      else
        $stdout.puts "Exclude UDP: #{@parameters[:exclude_udp].join(",")}\n"
                       .colorize :light_cyan unless @parameters[:exclude_udp].nil?
      end

      puts
      display_parameter :timeout, "Timeout"
      $stdout.puts
    end
  end

  def import_scanner
    @scanner_file = File.join $current_directory, 'source', 'scanner.rb'
    require @scanner_file
    @scanner = BunjoScan.new @parameters[:host], @parameters[:timeout]
  end

  def import_version_scanner
    @version_detecter_file = File.join $current_directory, 'source', 'version_detecter.rb'
    require @version_detecter_file
    @version_detecter = BunjoVersionDetect.new @parameters[:host]
  end

  def import_script_engine
    @script_engine_file = File.join $current_directory, 'source', 'scripts', 'script_engine.rb'
    require @script_engine_file
    @script_engine = ScriptEngine.new @parameters[:host], "", ""
  end

  def import_all_classes
    import_scanner
    import_version_scanner
    import_script_engine
  end

  def start
    case

    when @parameters[:help]
      print_help
      exit 0
    when @parameters[:tcp_ports] && @parameters[:udp_ports] && @parameters[:script]

    when @parameters[:tcp_ports] && @parameters[:script]

    when @parameters[:udp_ports] && @parameters[:script]

    when @parameters[:tcp_ports] && @parameters[:udp_ports]
      import_scanner

      tcp_threads = []
      udp_threads = []

      only_tcp_time = Time.now
      only_udp_time = Time.now

      $stdout.puts "PORT STATUS".colorize :light_white

      @parameters[:tcp_ports].reject { |port| @parameters[:exclude_tcp]&.include? port.to_i }.each do |tcp_port|
        tcp_threads << Thread.new { @scanner.tcp_scan tcp_port }
      end

      @parameters[:udp_ports].reject { |port| @parameters[:exclude_udp]&.include? port.to_i }.each do |udp_port|
        udp_threads << Thread.new { @scanner.udp_scan udp_port }
      end

      tcp_threads.each &:join
      udp_threads.each &:join

      $stdout.puts "\nTHE PASSING TIME (with timeout):\nTCP: #{Time.now - only_tcp_time}\nUDP: #{Time.now - only_udp_time}".colorize :light_white

    when @parameters[:tcp_ports]
      begin
        import_scanner

        tcp_threads = []
        only_tcp_time = Time.now

        $stdout.puts "PORT STATUS".colorize :light_white

        @parameters[:tcp_ports].reject { |port| @parameters[:exclude_tcp]&.include? port.to_i }.each do |tcp_port|
          tcp_threads << Thread.new { @scanner.tcp_scan tcp_port }
        end

        tcp_threads.each &:join

        $stdout.puts "\nTHE PASSING TIME (with timeout): #{Time.now - only_tcp_time}"
                       .colorize :light_white
      rescue Interrupt
        $stderr.puts "Program closed by user.".colorize :red
      end
    when @parameters[:udp_ports]
      import_scanner

      udp_threads = []
      only_udp_time = Time.now

      $stdout.puts "PORT STATUS".colorize :light_white

      @parameters[:udp_ports].reject { |port| @parameters[:exclude_udp]&.include? port.to_i }.each do |udp_port|
        udp_threads << Thread.new { @scanner.udp_scan udp_port }
      end

      udp_threads.each &:join

      $stdout.puts "\nTHE PASSING TIME (with timeout): #{Time.now - only_udp_time}".colorize :light_white
    when @parameters[:host].nil? && @parameters[:tcp_ports].nil? && @parameters[:udp_ports].nil?
      print_help
    else
      print_help
    end
  end
end

port_scanner = BunjoNET.new
port_scanner.display_parameters
port_scanner.start
