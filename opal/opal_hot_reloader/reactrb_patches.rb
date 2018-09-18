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
  # patches to handle new react error boundry call back
  module AddForceUpdate
    # latest hyperloop already has a force_update! method, but legacy hot
    # reloader expects it to be defined in React::Component.
    # Once older versions of Hyperloop are deprecated this can be removed.
    def force_update!
      Hyperloop::Component.force_update!
    end
  end
  module AddErrBoundry
    def self.included(base)
      base.after_error do |*err|
        @err = err
        Hyperloop::Component.force_update!
      end
      base.define_method :render do
        @err ? parse_display_and_clear_error : top_level_render
      end
    end

    def parse_display_and_clear_error
      e = @err[0]
      component_stack = @err[1]['componentStack'].split("\n ")
      @err = nil
      display_error(e, component_stack)
    end

    def display_error(e, component_stack)
      DIV do
        DIV { "Uncaught error: #{e}" }
        component_stack.each do |line|
          DIV { line }
        end
      end
    end
  end
end

class ReactrbPatches
  def self.patch!
    if defined?(::React::TopLevelRailsComponent) && ::React::TopLevelRailsComponent.respond_to?(:after_error)
       puts "new style"
      ::React::TopLevelRailsComponent.include ReactrbPatchModules::AddErrBoundry
      ::React::Component.extend ReactrbPatchModules::AddForceUpdate
    else
      puts "old style"
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
end
