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
    ws_url = "#{host}:#{port}"
    puts "Hot-Reloader connecting to #{ws_url}"
    %x{
      ws = new WebSocket('ws://' + #{ws_url});
      // console.log(ws);
      ws.onmessage = #{lambda { |e| reload(e) }}
    }
  end

  def reload(e)
    reload_request = JSON.parse(`e.data`)
    if reload_request[:type] == "ruby"
      puts "Reloading ruby #{reload_request[:filename]}"
      $eval_proc.call reload_request[:source_code]
      if @reload_post_callback
        @reload_post_callback.call
      else
        puts "not reloading code"
      end
    end
    if reload_request[:type] == "css"
      @css_reloader.reload(reload_request, `document`)
    end
  end

  # @param port [Integer] opal hot reloader port to connect to
  # @param reload_post_callback [Proc] optional callback to be called after re evaluating a file for example in react.rb files we want to do a React::Component.force_update!
  def initialize(port=25222, &reload_post_callback)
    @port = port
    @reload_post_callback  = reload_post_callback
    @css_reloader = CssReloader.new
  end
  # Opens a websocket connection that evaluates new files and runs the optional @reload_post_callback
  def listen
    connect_to_websocket(@port)
  end

  # convenience method to start a listen w/one line
  # @param port [Integer] opal hot reloader port to connect to. Defaults to 25222 to match opal-hot-loader default
  # @param reactrb [Boolean] whether or not the project runs reactrb. If true, the reactrb callback is automatically run after evaluation the updated code. Defaults to false.
  def self.listen(port=25222, reactrb=false)
    return if @server
    if reactrb
      if defined? ::React
        ReactrbPatches.patch!
        @server = OpalHotReloader.new(port) { React::Component.force_update! }
      else
        puts "This is not a React.rb app.  No React.rb hooks will be applied"
      end
    else
      @server = OpalHotReloader.new(port)
    end

    @server.listen
  end

end
