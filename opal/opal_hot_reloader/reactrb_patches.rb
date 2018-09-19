# patches to support reloading react.rb
module ReactrbPatchModules
  # add global force_update! method
  module ReactComponent
    def add_to_global_component_list(instance)
      (@global_component_list ||= Set.new).add instance
    end

    def remove_from_global_component_list(instance)
      @global_component_list.delete instance
    end

    def force_update!
      # components may be unmounted as a result of doing force_updates
      # so copy the list, and then check before updating each component
      return unless @global_component_list
      components = @global_component_list.to_a
      components.each do |comp|
        next unless @global_component_list.include? comp
        comp.force_update!
      end
    end
  end

  # patches to handle new react error boundry call back
  module AddErrBoundry
    def self.included(base)
      base.alias_method :pre_hot_loader_render, :render
      base.after_error do |*err|
        @err = err
        force_update!
      end
      base.define_method :render do
        @err ? parse_display_and_clear_error : pre_hot_loader_render
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

# React.rb needs to be patched so the we don't keep adding callbacks
class ReactrbPatches
  def self.patch!
    if defined?(::React::TopLevelRailsComponent) && ::React::TopLevelRailsComponent.respond_to?(:after_error)
      # new style:  Just add the error handler to the top level component
      ::React::TopLevelRailsComponent.include ReactrbPatchModules::AddErrBoundry
      # for compatibility with current opal-hot-reloader AddForceUpdate renames force_update!
      ::React::Component.extend ReactrbPatchModules::AddForceUpdate
    else
      # old style (pre lap28 / 0.99 legacy release)
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
