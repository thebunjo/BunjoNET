$current_directory = File.expand_path File.dirname __FILE__
SCRIPT_ENGINE_FILE = File.join file, 'source', 'scripts', 'script_engine'

require SCRIPT_ENGINE_FILE

class HTTP_AUTH < ScriptEngine
  def initialize host, port

  end
end