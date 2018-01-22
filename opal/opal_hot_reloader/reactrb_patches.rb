# patches to support reloading react.rb
module ReactrbPatchModules
  module ReactComponent
    def add_to_global_component_list(instance)
      (@global_component_list ||= Set.new).add instance
    end

    def remove_from_global_component_list(instance)
      @global_component_list.delete instance
    end

    def force_update!
      @global_component_list && @global_component_list.each(&:force_update!)
    end
  end
end

class ReactrbPatches
  # React.rb needs to be patched so the we don't keep adding callbacks
  def self.patch!
    ::React::Component.extend ReactrbPatchModules::ReactComponent # works

    ::React::Callbacks.alias_method :original_run_callback, :run_callback # works
    # Easiest place to hook into all components lifecycles
    ::React::Callbacks.define_method(:run_callback) do |name, *args| # works
      React::Component.add_to_global_component_list self if name == :before_mount
      original_run_callback name, *args
      React::Component.remove_from_global_component_list self if name == :before_unmount
    end
  end
end
