require 'opal_hot_reloader/reactrb_patches'
require 'opal_hot_reloader/css_reloader'
require 'opal-parser' # gives me 'eval', for hot-loading code

require 'json'

# Opal client to support hot reloading
$eval_proc = proc { |s| eval s }
class OpalHotReloader

  def connect_to_websocket(port)
    host = `window.location.host`.sub(/:\d+/, '')
    host = '127.0.0.1' if host == ''
    protocol = `window.location.protocol` == 'https:' ? 'wss:' : 'ws:'
    ws_url = "#{host}:#{port}"
    puts "Hot-Reloader connecting to #{ws_url}"
    ws = `new WebSocket(#{protocol} + '//' + #{ws_url})`
    `#{ws}.onmessage = #{lambda { |e| reload(e) }}`
    `setInterval(function() { #{ws}.send('') }, #{@ping * 1000})` if @ping
  end

  def notify_error(reload_request)
    msg = "OpalHotReloader #{reload_request[:filename]} RELOAD ERROR:\n\n#{$!}"
    puts msg
    alert msg if use_alert?
  end

  @@USE_ALERT = true
  def self.alerts_on!
    @@USE_ALERT = true
  end
  
  def self.alerts_off!
    @@USE_ALERT = false
  end

  def use_alert?
    @@USE_ALERT
  end
  
  def reload(e)
    reload_request = JSON.parse(`e.data`)
    if reload_request[:type] == "ruby"
      puts "Reloading ruby #{reload_request[:filename]}"
      begin
        $eval_proc.call reload_request[:source_code]
      rescue
        notify_error(reload_request)
      end
      if @reload_post_callback
        @reload_post_callback.call
      else
        puts "no reloading callback to call"
      end
    end
    if reload_request[:type] == "css"
      @css_reloader.reload(reload_request, `document`)
    end
  end

  # @param port [Integer] opal hot reloader port to connect to
  # @param reload_post_callback [Proc] optional callback to be called after re evaluating a file for example in react.rb files we want to do a React::Component.force_update!
def initialize(port=25222, ping=nil, &reload_post_callback)
  @port = port
  @reload_post_callback  = reload_post_callback
  @css_reloader = CssReloader.new
  @ping = ping
end
# Opens a websocket connection that evaluates new files and runs the optional @reload_post_callback
def listen
  connect_to_websocket(@port)
end

# convenience method to start a listen w/one line
# @param port [Integer] opal hot reloader port to connect to. Defaults to 25222 to match opal-hot-loader default
# @deprecated reactrb - this flag no longer necessary and will be removed in gem release 0.2
def self.listen(port=25222, reactrb=false, ping=nil)
  return if @server
  if reactrb
    warn "OpalHotReloader.listen(#{port}): reactrb flag is deprectated and will be removed in gem release 0.2. React will automatically be detected"
  end
  create_framework_aware_server(port, ping)
end
# Automatically add in framework specific hooks

def self.create_framework_aware_server(port, ping)
  if defined? ::React
    ReactrbPatches.patch!
    @server = OpalHotReloader.new(port, ping) do
      if defined?(Hyperloop) && 
         defined?(Hyperloop::ClientDrivers) &&
         Hyperloop::ClientDrivers.respond_to?(:initialize_client_drivers_on_boot)
        Hyperloop::ClientDrivers.initialize_client_drivers_on_boot 
      end
      React::Component.force_update!
    end 
  else
    @server = OpalHotReloader.new(port, ping)
  end
  @server.listen
end

end
