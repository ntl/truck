require_relative "truck/version"
require_relative "truck/string_inflections"
require_relative "truck/autoloader"
require_relative "truck/context"
require_relative "truck/const_resolver"

module Truck
  extend self

  attr :contexts
  @contexts = {}

  attr_accessor :debug_mode

  def define_context(name, params = {})
    root, parent, autoload_paths = extract_args!(
      params,
      :root,
      parent: nil,
      autoload_paths: ['.'],
    )
    contexts[name] = Context.new(name, root, parent, autoload_paths)
  end

  def boot!
    contexts.each_value &:boot!
  end

  def reset!
    shutdown!
    boot!
  end
  alias_method :reload!, :reset!

  def shutdown!
    each_booted_context.to_a.reverse.each &:shutdown!
  end

  Error = Class.new StandardError

  private

  def each_booted_context(&block)
    return to_enum(:each_booted_context) unless block_given?
    contexts.each_value.select(&:booted?).each(&block)
  end

  def extract_args!(hsh, *mandatory)
    optional = mandatory.pop if mandatory.last.is_a? Hash
    args = mandatory.map do |key|
      hsh.fetch key do raise ArgumentError, "missing keyword: #{key}" end
    end
    optional.each do |key, default|
      args.<< hsh.fetch key, default
    end
    args
  end
end

# Load this last so that when truck itself has unresolvable constants, we throw
# up vanilla ruby NameErrors.
require_relative "truck/core_ext"
