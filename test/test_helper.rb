require "bundler"
Bundler.setup

require "minitest/autorun"
require "minitest/red_green"

require "fakefs/safe"
require "ostruct"
require "pathname"
require "stringio"

require_relative "../lib/truck"

$LOAD_PATH << "test/support"

Minitest::Test.class_eval do
  autoload :FakesFilesystem, "fakes_filesystem"
  autoload :TestsAutoloading, "tests_autoloading"

  def after_teardown
    Truck.shutdown!
  end
end

class Binding
  def method_missing(sym, *)
    return super unless sym == :pry
    FakeFS.without do
      require 'pry'
      pry
    end
  end
end
