class BunjoNET
  def initialize
    require 'optparse'
    require 'colorize'

    @parameters = {
      help: false, host: nil, show_tcp_close: false, show_udp_close: false,
      timeout: 1, threads: 5, show_scripts: false, script_help: nil,
      tcp_all: false, udp_all: false, script: nil, script_class: nil,
      exclude_tcp: nil, exclude_udp: nil, show_reason: false,

      script_args: {
        port: {
          ftp: 21,
          ssh: 22,
          telnet: 23,
          http: 80,
          https: 443,
      },

        use_ssl: false, user_list: nil,
        wordlist: nil, host: nil,
      }
    }

    @scripts = %w[
    anon-ftp http-auth ftp-brute mysql-brute
    pop3-brute smb-brute snmp-brute ssh-brute
    telnet-brute vnc-brute dns-records file-scan
    http-headers http-slowloris smb-flood ftp-user-enum
    mysql-user-enum smtp-user-enum banner whois
    proftpd-backdoor vsftpd-backdoor
]

    @used_scripts = []

    parse_options

    $current_directory = File.expand_path File.dirname __FILE__
  end

  def banner
    banner_text = <<-'BANNER'
--------------------------------------    
.                    .   ..---..---.  
|              o     |\  ||      |    
|.-. .  . .--. . .-. | \ ||---   |     
|   )|  | |  | |(   )|  \||      |      
'`-' `--`-'  `-| `-' '   ''---'  '    
               ;                      
            `-'     
--------------------------------------     
Developed By Bunjo
Github: https://github.com/thebunjo/BunjoNET
--------------------------------------
    BANNER

    $stdout.puts banner_text.colorize :magenta
  end

  def parse_options
    begin
      OptionParser.new do |params|
        params.on "--host HOST", String, "Define the target host" do |host|
          if host.start_with? "https://" or host.start_with? "http://"
            $stderr.puts "Error: Please enter a valid host.".colorize :red
            exit 1
          else
            @parameters[:host] = host
          end
        end

        params.on "--threads THREADS", Integer, "Enter threads to parallel scan (default: 5)" do |threads|
          @parameters[:threads] = threads
        end

        params.on "--show-tcp-close", String, "Add closed ports output to output." do
          @parameters[:show_tcp_close] = true
        end

        params.on "--show-udp-close", String, "Add closed ports output to output." do
          @parameters[:show_udp_close] = true
        end

        params.on "--script SCRIPT", String, "Select scripts to use" do |script|
          @script_used = false
          if script.include? ","
            scripts = script.split ","
            scripts.each do |script_control|
              if @scripts.include? script_control
                @used_scripts.append script_control
                @script_used = true
              end
            end
          else
            if @scripts.include? script
              @parameters[:script] = [script]
              @used_scripts.append script
              @script_used = true
            end
          end
        end

        params.on "--reason", String, "Add closed ports output to output." do
          @parameters[:show_reason] = true
        end

        params.on "--script-args SCRIPT_ARGS", String, "Define args to use on script attack" do |script_args|
          @parameters[:script_args] = script_args
        end

        params.on "--exclude-tcp EXCLUDE_TCP_PORTS", String, "Define tcp ports to skip on scan" do |exclude_tcp|
          if exclude_tcp.include? "-"
            @exclude_range_tcp = exclude_tcp.split "-"
            @exclude_tcp_range_used = true
            if @exclude_range_tcp[0].to_i < @exclude_range_tcp[1].to_i
              @parameters[:exclude_tcp] = (@exclude_range_tcp[0].to_i..@exclude_range_tcp[1].to_i)
            elsif @exclude_range_tcp[0].to_i == @exclude_range_tcp[1].to_i
              @parameters[:exclude_tcp] = [@exclude_range_tcp[0].to_i]
            end
          elsif exclude_tcp.include? ","
            @parameters[:exclude_tcp] = exclude_tcp.split ",".map &:to_i
          else
            @parameters[:exclude_tcp] = [exclude_tcp.to_i]
          end
        end

        params.on "--exclude-udp EXCLUDE_UDP_PORTS", String, "Define udp ports to skip on scan" do |exclude_udp|
          if exclude_udp.include? "-"
            @exclude_range_udp = exclude_udp.split "-"
            @exclude_udp_range_used = true
            if @exclude_range_udp[0].to_i < @exclude_range_udp[1].to_i
              @parameters[:exclude_udp] = (@exclude_range_udp[0].to_i..@exclude_range_udp[1].to_i)
            elsif @exclude_range_udp[0].to_i == @exclude_range_udp[1].to_i
              @parameters[:exclude_udp] = [@exclude_range_udp[0].to_i]
            end
          elsif exclude_udp.include? ","
            @parameters[:exclude_udp] = exclude_udp.split ",".map &:to_i
          else
            @parameters[:exclude_udp] = [exclude_udp.to_i]
          end
        end

        params.on "--show-scripts", "Print all scripts" do |show_scripts|
          @parameters[:show_scripts] = true
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

  def save_output

  end

  def print_scripts
    scripts_text = -<<'SCRPITS_TEXT'
SCRIPTS

  AUTH
    - anon-ftp
    - http-auth
  
  BRUTE
    - ftp-brute
    - mysql-brute
    - pop3-brute
    - smb-brute
    - snmp-brute
    - ssh-brute
    - telnet-brute
    - vnc-brute
  
  DISCOVER
    - dns-records
    - file-scan
    - http-headers
    
  VULN
    - proftpd-backdoor
    - vsftpd-backdoor
 
   DOS
    - http-slowloris
    - smb-flood
  
  ENUM
    - ftp-user-enum
    - mysql-user-enum
    - smb-user-enum
    - snmp-user-enum

  INFO
    - banner
    - whois
    
SCRPITS_TEXT

    $stdout.puts scripts_text.colorize :light_white
  end

  def print_help
    puts
    help_text = <<-'HELP_TEXT'
HELP STAGE

    DEFINE TARGET
      --host HOST: Define the target host

    PORT SCANNING
      TCP
        --tcp: TCP PORTS: Ports for TCP scanning      
        --tcp all: Scan all tcp ports
        --exclude-tcp PORTS: TCP ports to skip on scan
        --show-tcp-close: Show closed tcp ports
      
      UDP
        --udp: UDP PORTS: Port for UDP scanning
        --udp all: Scan all udp ports
        --exclude-udp PORTS: UDP ports to skip on scan
        --show-udp-close: Show closed udp ports
       
      --banner: Use this for get the banners of the ports
      --exclude-banner TCP_PORT: Do not get banners for defined ports 

    TIMING
      --timeout TIMEOUT: Enter timeout time (default: 1)

    HELP
      --help: Prints this text message
    
    SCRIPTING
      --script SCRIPT: Select scripts to use
      --script-args SCRIPT: Define args to use on script attack

      --show-scripts: Prints all scripts
      --script-help SCRIPT_NAME: Informations for defined script
  
    MECHANISM
      --threads THREADS: Enter threads to parallel scan (default: 5)
    
    SAVE OUTPUT
      --output FILE: Enter file to save output 

    EXAMPLES
      bunjoNET --host example.com --tcp 21,80,3306 --udp 53
      bunjoNET --host example.com --tcp 80,3306 --timeout 0.5
    
    HELP_TEXT

    $stdout.puts help_text.colorize :light_white
  end

  def display
    banner

    $stdout.puts "| SCAN INFORMATION".colorize :light_white
    $stdout.puts "|".colorize :light_white
    $stdout.puts "| Host: #{@parameters[:host]}".colorize :light_white
    $stdout.puts "|".colorize :light_white

    $stdout.puts "| Timeout: #{@parameters[:timeout]}".colorize :light_white
    $stdout.puts "|".colorize :light_white

    $stdout.puts "| Script Engine: #{@used_scripts.join ","}".colorize :light_white if @script_used
    $stdout.puts "|".colorize :light_white if @script_used

    $stdout.puts "| Ports:".colorize :light_white

    if @parameters[:tcp_ports].is_a? Array and @parameters[:tcp_ports]
      $stdout.puts "|\tTCP: #{@parameters[:tcp_ports].join(", ")}".colorize :light_white
    elsif @parameters[:tcp_ports].is_a? Range and @parameters[:tcp_ports]
      $stdout.puts "|\tTCP Range: #{@parameters[:tcp_ports]}"
                     .colorize :light_white
    end

    if @parameters[:exclude_tcp].is_a? Array
      $stdout.puts "|\tExclude TCP: #{@parameters[:exclude_tcp].join(", ")}"
                     .colorize :light_white unless @parameters[:exclude_tcp].nil?
    elsif @parameters[:exclude_tcp].is_a? Range
      $stdout.puts "|\tExclude TCP Range: #{@parameters[:exclude_tcp]}"
                     .colorize :light_white unless @parameters[:exclude_tcp].nil?
    end

    $stdout.puts "|".colorize :light_white unless @parameters[:udp_ports].nil?

    if @parameters[:udp_ports].is_a? Array
      $stdout.puts "|\tUDP: #{@parameters[:udp_ports].join(", ")}".colorize :light_white
    elsif @parameters[:udp_ports].is_a? Range
      $stdout.puts "|\tUDP Range: #{@parameters[:udp_ports]}"
                     .colorize :light_white
    end

    if @parameters[:exclude_udp].is_a? Array
      $stdout.puts "|\tExclude UDP: #{@parameters[:exclude_udp].join(", ")}"
                     .colorize :light_white unless @parameters[:exclude_udp].nil?
    elsif @parameters[:exclude_udp].is_a? Range
      $stdout.puts "|\tExclude UDP Range: #{@parameters[:exclude_udp]}"
                     .colorize :light_white unless @parameters[:exclude_udp].nil?
    end

    $stdout.puts "|".colorize :light_white
  end

  def import_scanner_tcp
    @tcp_scanner_file = File.join $current_directory, 'utils', 'tcp_scanner', 'tcp_scan.rb'
    require @tcp_scanner_file
    @tcp_scanner = BunjoScanTCP.new @parameters[:host], @parameters[:timeout], @parameters[:show_tcp_close], @parameters[:show_reason]
  end

  def import_scanner_udp
    @udp_scanner_file = File.join $current_directory, 'utils', 'udp_scanner', 'udp_scan.rb'
    require @udp_scanner_file
    @udp_scanner = BunjoScanUDP.new @parameters[:host], @parameters[:timeout]
  end

  def import_version_scanner
    @version_detecter_file = File.join $current_directory, 'utils', 'version_detect', 'version_detecter.rb'
    require @version_detecter_file
    @version_detecter = BunjoVersionDetect.new @parameters[:host]
  end

  def import_script_engine
    @script_engine_file = File.join $current_directory, 'source', 'scripts', 'script_engine.rb'
    require @script_engine_file
    @script_engine = ScriptEngine.new @parameters[:host]
  end

  def perform_script_scans
    import_script_engine

    @parameters[:script].each do |script|
      if @scripts.include? script
        @script_engine.control_script script
      end
    end
  end

    def perform_tcp_scan
      import_scanner_tcp

      tcp_threads = []

      @parameters[:tcp_ports].reject { |port| @parameters[:exclude_tcp]&.include? port.to_i }.each do |tcp_port|
        tcp_threads << Thread.new { @tcp_scanner.tcp_scan tcp_port }
      end

      tcp_threads.each &:join
    end

    def perform_udp_scan
      import_scanner_udp

      udp_threads = []

      @parameters[:udp_ports].reject { |port| @parameters[:exclude_udp]&.include? port.to_i }.each do |udp_port|
        udp_threads << Thread.new { @udp_scanner.udp_scan udp_port }
      end

      udp_threads.each &:join
    end

    def import_all_classes
      import_scanner_tcp
      import_scanner_udp
      import_version_scanner
      import_script_engine
    end

    def start
      begin

        case

        when @parameters[:help]
          print_help
          exit 0

        when @parameters[:show_scripts]
          print_scripts
          exit 0

        when @parameters[:tcp_ports] && @parameters[:udp_ports]
          display
          $stdout.puts "| PORT STATUS".colorize :light_white

          time_now = Time.now

          perform_tcp_scan
          perform_udp_scan

          $stdout.puts "|".colorize :light_white
          $stdout.puts "| THE PASSING TIME (with timeout): #{Time.now - time_now}".colorize :light_white
        when @parameters[:tcp_ports]
          display
          case

          when @parameters[:script]
            $stdout.puts "PORT STATUS".colorize :light_white

            time_now = Time.now

            perform_tcp_scan
            perform_script_scans

            $stdout.puts "|".colorize :light_white
            $stdout.puts "| THE PASSING TIME (with timeout): #{Time.now - time_now}".colorize :light_white
          else
            $stdout.puts "| PORT STATUS".colorize :light_white

            time_now = Time.now

            perform_tcp_scan

            $stdout.puts "|".colorize :light_white
            $stdout.puts "| THE PASSING TIME (with timeout): #{Time.now - time_now}".colorize :light_white
          end
        when @parameters[:udp_ports]
          display
          $stdout.puts "| PORT STATUS".colorize :light_white

          time_now = Time.now

          perform_udp_scan

          $stdout.puts "|".colorize :light_white
          $stdout.puts "| THE PASSING TIME (with timeout): #{Time.now - time_now}".colorize :light_white
        when @parameters[:host].nil? && @parameters[:tcp_ports].nil? && @parameters[:udp_ports].nil?
          print_help
        else
          print_help
        end
      end
    rescue Interrupt
      $stderr.puts "Program closed by user.".colorize :red
    end
  end

  port_scanner = BunjoNET.new
  port_scanner.start
