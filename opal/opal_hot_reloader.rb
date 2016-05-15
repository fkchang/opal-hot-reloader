require 'opal_hot_reloader/reactrb_patches'
require 'opal-parser' # gives me 'eval', for hot-loading code

# Opal client to support hot reloading
class OpalHotReloader

  def connect_to_websocket(port)
    host = `window.location.host`.sub(/:\d+/, '')
    host = '127.0.0.1' if host == ''
    ws_url = "#{host}:#{port}"
    puts "Connecting to #{ws_url}"
    `ws = new WebSocket('ws://' + #{ws_url});`
    `console.log(ws);
    
    ws.onmessage = #{lambda { |e| reload(e) }}
`
  end
  #  // ws.onmessage = #{lambda { |e| alert(`e.data`); eval(`e.data`) }}
  def reload(e)
    code = `e.data`
    eval code
    if @reload_post_callback
      @reload_post_callback.call
    else
      puts "not reloading code"

    end
  end

  # @param port [Integer] opal hot reloader port to connect to
  # @param reload_post_callback [Proc] optional callback to be called after re evaluating a file for example in react.rb files we want to do a React::Component.force_update!
  def initialize(port=25222, &reload_post_callback)
    @port = port
    @reload_post_callback  = reload_post_callback
  end
  # Opens a websocket connection that evaluates new files and runs the optional @reload_post_callback
  def listen
    connect_to_websocket(@port)
  end
  
  # convenience method to start a listen w/one line
  # @param port [Integer] opal hot reloader port to connect to
  # @param reactrb [Boolean] whether or not the project runs reactrb. If true, the reactrb callback is automatically run after evaluation the updated code
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
