module Truck
  class Autoloader
    attr :base_nibbles, :context, :file, :from, :dir_paths

    def initialize(from, file)
      @from = from
      @file = file
      @context, @base_nibbles = fetch_context_and_base_nibbles
      @dir_paths = [nil]
    end

    def <<(const_name)
      raise_name_error!(const_name) unless context
      @dir_paths = each_possible_const(const_name).reduce [] do |new_paths, possible_const|
        resolved_const = context.resolve_const possible_const, file
        throw :const, resolved_const if resolved_const
        new_paths << possible_const if possible_namespace?(possible_const)
        new_paths
      end
      raise_name_error!(const_name) if dir_paths.empty?
    end

    def each_possible_const(const_name)
      return to_enum(:each_possible_const, const_name) unless block_given?
      dir_paths.each do |dir_path|
        base_nibbles.map { |e| yield constify(e, *dir_path, const_name) }
        yield constify(*dir_path, const_name)
      end
    end

    def possible_namespace?(possible_const)
      snaked = StringInflections.to_snake_case possible_const
      context.root.join(snaked).directory?
    end

    def constify(*nibbles)
      nibbles.compact.join '::'
    end

    def raise_name_error!(const_name = dir_paths.last)
      message = "uninitialized constant #{const_name}"
      message << " (in #{context.mod})" if context
      raise NameError, message
    end

    # given "Foo::Bar::Baz", return ["Foo::Bar::Baz", "Foo::Bar", etc.]
    def fetch_context_and_base_nibbles
      each_base_nibble.to_a.reverse.reduce [] do |ary, (mod, const)|
        owner = Truck.contexts.each_value.detect { |c| c.context_for? mod }
        return [owner, ary] if owner
        ary.map! do |e| e.insert 0, '::'; e.insert 0, const; end
        ary << const
      end
      nil
    end

    # given "Foo::Bar::Baz", return ["Foo", "Bar", "Baz"]
    def each_base_nibble
      return to_enum(:each_base_nibble) unless block_given?
      from.name.split('::').reduce Object do |mod, const|
        mod = mod.const_get const
        yield [mod, const]
        mod
      end
    end

    module ThreadedState
      def autoloaders
        @autoloaders ||= {}
      end

      def current_autoloader
        autoloaders[current_thread_id]
      end

      def set_current_autoloader(to)
        autoloaders[current_thread_id] = to
      end

      def unset_current_autoloader
        set_current_autoloader nil
      end

      def current_thread_id
        Thread.current.object_id
      end
    end
    extend ThreadedState

    module HandleConstMissing
      def handle(*args)
        found_const = catch :const do
          handle! *args and return NullModule
        end
        throw :const, found_const
      rescue NameError => name_error; raise name_error
      ensure
        unset_current_autoloader if found_const or name_error
      end

      def handle!(const_name, from, current_file = nil)
        autoloader = current_autoloader || new(from, current_file)
        autoloader << String(const_name)
        set_current_autoloader autoloader
      end
    end
    extend HandleConstMissing

    module NullModule
      extend self

      def method_missing(*)
        Autoloader.current_autoloader.raise_name_error!
      ensure
        Autoloader.unset_current_autoloader
      end
    end
  end
end
