module Truck
  class Context
    attr :autoload_paths, :name, :root

    def initialize(name, root, parent, autoload_paths)
      @name   = name
      @root   = Pathname(root)
      @parent = parent
      @autoload_paths = expand_autoload_paths autoload_paths
    end

    class << self
      def owner(const)
        owner, _ = Autoloader.owner_and_ascending_nibbles const
        owner
      end
    end

    def boot!
      parent.const_set name, build_mod
    end

    def mod
      return nil unless parent and parent.const_defined? name
      parent.const_get name 
    end

    def context_for?(other_mod)
      mod == other_mod or other_mod.included_modules.include? mod
    end

    def booted?
      mod ? true : false
    end

    def eager_load!
      Dir[root.join('**/*.rb')].each do |rb_file|
        load_file rb_file
      end
    end

    def load_file(rb_file)
      ruby_code = File.read rb_file
      mod.module_eval ruby_code, rb_file.to_s
    end

    def parent
      return Object unless @parent
      Truck.contexts.fetch(@parent.to_sym).mod
    end

    def resolve_const(expanded_const, skip = nil)
      build_const_resolver(expanded_const, Array[skip]).resolve
    end

    def shutdown!
      parent.send :remove_const, name
    end

    private

    def build_const_resolver(expanded_const, skip_files)
      ConstResolver.new(
        context: self,
        expanded_const: String(expanded_const).dup.freeze,
        skip_files: skip_files,
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
