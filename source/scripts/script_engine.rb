class ScriptEngine
  def initialize host, protocol, scripts
    @host = host
    @protocol = protocol
    @scripts = [scripts]
  end

  class Discovering
    def initialize engine
      @engine = engine

      puts "Host: #{@engine.instance_variable_get :@host}"
      puts "Protocol: #{@engine.instance_variable_get :@protocol}"
      puts "Script Class: Discovering"
      puts "Script: #{@engine.instance_variable_get :@scripts}"
    end
  end

  class VulnerabilityDetect
    def initialize engine
      @engine = engine
      puts @engine.instance_variable_get :@host

      puts "Host: #{@engine.instance_variable_get :@host}"
      puts "Protocol: #{@engine.instance_variable_get :@protocol}"
      puts "Script Class: Vulnerability Detect"
      puts "Script: #{@engine.instance_variable_get :@scripts}"
    end
  end

  class InformationGathering
    def initialize engine
      @engine = engine
      puts @engine.instance_variable_get :@host

      puts "Host: #{@engine.instance_variable_get :@host}"
      puts "Protocol: #{@engine.instance_variable_get :@protocol}"
      puts "Script Class: Information Gathering"
      puts "Script: #{@engine.instance_variable_get :@scripts}"
    end
  end
end