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
      return unless base.respond_to? :after_error
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
end

# React.rb needs to be patched so the we don't keep adding callbacks
class ReactrbPatches
  def self.patch!
    ::React::Component.extend ReactrbPatchModules::ReactComponent # works

    ::React::Callbacks.alias_method :original_run_callback, :run_callback # works
    # Easiest place to hook into all components lifecycles
    ::React::Callbacks.define_method(:run_callback) do |name, *args| # works
      ::React::Component.add_to_global_component_list self if name == :before_mount
      original_run_callback name, *args
      ::React::Component.remove_from_global_component_list self if name == :before_unmount
    end

    return unless defined?(::React::TopLevelRailsComponent)
    ::React::TopLevelRailsComponent.include ReactrbPatchModules::AddErrBoundry
  end
end
