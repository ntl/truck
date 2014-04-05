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
    shutdown_all_contexts!
    boot!
  end
  alias_method :reload!, :reset!

  def shutdown!
    shutdown_all_contexts!
    contexts.clear
  end

  Error = Class.new StandardError

  private

  def shutdown_all_contexts!
    contexts.each_value do |context|
      context.shutdown! if context.booted?
    end
  end
end
