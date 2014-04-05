module Truck
  using StringInflections

  class Context
    class ConstResolver
      attr :current_path, :autoload_paths, :context, :expanded_const

      def initialize(context:, expanded_const:, autoload_paths: [''])
        @autoload_paths = autoload_paths
        @context        = context
        @expanded_const = expanded_const
      end

      def autoload_paths=(paths)
        autoload_paths.clear
        autoload_paths.concat paths
      end

      def const_get
        walk_const_parts.reduce context.mod do |mod, const_part|
          return nil unless mod.const_defined?(const_part)
          mod.const_get const_part
        end
      end

      def each_autoload_path
        autoload_paths.each do |autoload_path|
          @current_path = context.root.join autoload_path
          yield
        end
        @current_path = nil
      end

      def each_possible_rb_file
        each_autoload_path do
          base_path = current_path.join expanded_const.to_snake_case
          each_rb_file_from_base_path base_path do |rb_file|
            yield rb_file if File.exist?(rb_file)
          end
        end
      end

      def each_rb_file_from_base_path(base_path)
        base_path.ascend do |path|
          return if path == context.root
          rb_file = path.sub_ext '.rb'
          yield rb_file if rb_file.file?
        end
      end

      def resolve
        check_already_loaded or resolve!
      end

      def resolve!
        each_possible_rb_file do |rb_file|
          context.load_file rb_file
          check_loaded rb_file
        end
        const_get
      end

      def walk_const_parts(const = expanded_const)
        return to_enum(:walk_const_parts, const) if block_given?
        const.split '::'
      end

      def check_already_loaded
        walk_const_parts.reduce context.mod do |mod, const_part|
          return nil unless mod.const_defined? const_part
          mod.const_get const_part
        end
      end

      def check_loaded(rb_file)
        expected_const = expected_const_defined_in_rb_file rb_file
        walk_const_parts(expected_const).reduce context.mod do |mod, const_part|
          mod.const_defined?(const_part) or
            raise AutoloadError.new(const: expected_const, rb_file: rb_file)
          mod.const_get const_part
        end
      end

      def expected_const_defined_in_rb_file(rb_file, autoload_path: current_path)
        rel_path = rb_file.sub_ext('').relative_path_from(autoload_path).to_s
        matcher = %r{\A(#{rel_path.to_camel_case})}i
        expanded_const.match(matcher).captures.fetch 0
      end
    end
  end
end
