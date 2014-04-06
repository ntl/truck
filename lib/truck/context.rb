module Truck
  class Context
    attr :autoload_paths, :mod, :name, :root

    def initialize(name, parent: nil, root:, autoload_paths: ['.'])
      @name   = name
      @root   = Pathname(root)
      @parent = parent
      @mod    = build_mod
      @autoload_paths = expand_autoload_paths autoload_paths
    end

    class << self
      def owner(const)
        owner, _ = Autoloader.owner_and_ascending_nibbles const
        owner
      end
    end

    def boot!
      parent.const_set name, mod
    end

    def booted?
      parent.const_defined? name
    end

    def eager_load!
      Dir[root.join('**/*.rb')].each do |rb_file|
        load_file rb_file
      end
    end

    def load_file(rb_file)
      mod.module_eval File.read(rb_file), rb_file.to_s
    end

    def parent
      return Object unless @parent
      Truck.contexts.fetch(@parent.to_sym).mod
    end

    def reset!
      shutdown!
      @mod = build_mod
      boot!
    end
    alias_method :reload!, :reset!

    def resolve_const(expanded_const)
      build_const_resolver(expanded_const).resolve
    end

    def shutdown!
      parent.send(:remove_const, name)
    end

    private

    def build_const_resolver(expanded_const)
      ConstResolver.new(
        context: self,
        expanded_const: String(expanded_const).dup.freeze,
      )
    end

    def build_mod
      mod = Module.new
      mod.singleton_class.class_exec root do |__root__|
        define_method :root do __root__ ; end
      end
      mod
    end

    def expand_autoload_paths(paths)
      paths.map do |path| root.join path; end
    end

  end

  class AutoloadError < NameError
    attr :const, :rb_file

    def initialize(const:, rb_file:)
      @const   = const
      @rb_file = rb_file
    end

    def message
      "Expected #{rb_file} to define #{const}"
    end
  end
end
