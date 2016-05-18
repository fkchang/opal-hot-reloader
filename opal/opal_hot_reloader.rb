require 'opal_hot_reloader/reactrb_patches'
require 'opal-parser' # gives me 'eval', for hot-loading code
require 'json'

# Opal client to support hot reloading
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
      eval reload_request[:source_code]
      if @reload_post_callback
        @reload_post_callback.call
      else
        puts "not reloading code"
      end
    end
    if reload_request[:type] == "css"
      url = reload_request[:url]
      puts "Reloading CSS: #{url}"
      %x{
        var toAppend = "t_hot_reload=" + (new Date()).getTime();
        var links = document.getElementsByTagName("link");
        for (var i = 0; i < links.length; i++) {
          var link = links[i];
          if (link.rel === "stylesheet" && link.href.indexOf(#{url}) >= 0) {
            if (link.href.indexOf("?") === -1) {
              link.href += "?" + toAppend;
            } else {
              if (link.href.indexOf("t_hot_reload") === -1) {
                link.href += "&" + toAppend;
              } else {
                link.href = link.href.replace(/t_hot_reload=\d{13}/, toAppend)
              }
            }
          }
        }
      }
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
