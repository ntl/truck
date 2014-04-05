require_relative "truck/version"
require_relative "truck/string_inflections"
require_relative "truck/autoloader"
require_relative "truck/context"
require_relative "truck/const_resolver"

module Truck
  extend self

  attr :contexts
  @contexts = {}

  def define_context(name, **params)
    contexts[name] = Context.new(name, **params)
  end

  def boot!
    contexts.each_value(&:boot!)
  end

  def reset!
    each_booted_context &:reset!
  end
  alias_method :reload!, :reset!

  def shutdown!
    each_booted_context &:shutdown!
  end

  Error = Class.new StandardError

  private

  def each_booted_context(&block)
    return to_enum(:each_booted_context) unless block_given?
    contexts.each_value.select(&:booted?).each(&block)
  end
end

# Load this last so that when truck itself has unresolvable constants, we throw
# up vanilla ruby NameErrors.
require_relative "truck/core_ext"
