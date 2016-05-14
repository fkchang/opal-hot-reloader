require 'opal'
require "opal_hot_reloader/version"
require "opal_hot_reloader/server"

module OpalHotReloader
  # Your code goes here...
end

Opal.append_path(File.expand_path(File.join('..', '..', 'opal'), __FILE__).untaint)
