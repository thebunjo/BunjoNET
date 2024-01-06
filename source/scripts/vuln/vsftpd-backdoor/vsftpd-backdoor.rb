$current_directory = File.expand_path File.dirname __FILE__
SCRIPT_ENGINE_FILE = File.join file, 'source', 'scripts', 'script_engine'

require SCRIPT_ENGINE_FILE

class VSFTPD_BACKDOOR < ScriptEngine
  def initialize host, port
    @vsftpd_host = @host
    @vsftpd_port = @port
  end
end