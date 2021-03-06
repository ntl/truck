require 'test_helper'

class ContextTest < Minitest::Test
  include FakesFilesystem

  def setup
    @context = Truck.define_context :Foo, root: "/foo"
    @context.boot!
  end

  def test_resolving_constant
    mod = @context.resolve_const(:A)
    assert_autoloaded_module 'A', mod
  end

  def test_resolving_deep_constant
    mod = @context.resolve_const('A::AA')
    assert_autoloaded_module 'A::AA', mod
  end

  def test_resolving_inner_constant
    mod = @context.resolve_const('A::AB::ABA')
    assert_autoloaded_module 'A::AB::ABA', mod
  end

  def test_parent_namespace_defined_in_child
    mod = @context.resolve_const('B::BA')
    assert_autoloaded_module 'B::BA', mod
  end

  def test_returns_nil_if_constant_isnt_defined
    assert_nil @context.resolve_const(:Abracadabra)
  end

  def test_returns_constant_that_has_already_been_resolved
    @context.resolve_const(:A)
    File.write '/foo/a.rb', "raise 'should not load this file'"
    @context.resolve_const(:A)
  end

  def test_raises_error_if_corresponding_file_did_not_define_constant
    File.write "/foo/abracadabra.rb", ""

    exception = assert_raises(Truck::AutoloadError) do
      @context.resolve_const(:Abracadabra)
    end

    expected_message = %r{Expected /foo/abracadabra\.rb to define Abracadabra}
    assert_match expected_message, exception.message
  end

  def test_nesting_context
    nested_context = Truck.define_context :Bar, root: "/bar", parent: 'Foo'
    nested_context.boot!

    mod = nested_context.resolve_const('A')
    assert_autoloaded_module 'Bar::A', mod
  end

  def test_eager_load
    refute Foo.const_defined?(:A)
    @context.eager_load!
    assert Foo.const_defined?(:A)
  end

  def test_shutdown_removes_const
    assert @context.booted?
    @context.shutdown!
    refute @context.booted?
  end

  def test_autoload_path_defaults_to_root
    assert_equal %w(/foo), Truck.contexts.fetch(:Foo).autoload_paths.map(&:to_s)
  end

  def test_explicit_autoload_paths
    context = Truck.define_context :MultipleAutoloadPaths, root: "/", autoload_paths: %w(foo bar)
    context.boot!

    mod = context.resolve_const('A')
    assert_kind_of Module, mod
    assert_equal 'MultipleAutoloadPaths::A', mod.name

    mod = context.resolve_const('B::BA')
    assert_kind_of Module, mod
    assert_equal 'MultipleAutoloadPaths::B::BA', mod.name
  end
  
  def test_root_defined_on_mod
    assert_equal Pathname("/foo"), Foo.root
  end

  private

  def assert_autoloaded_module(expected_name, mod)
    assert_kind_of Module, mod
    assert_equal "Foo::#{expected_name}", mod.name
    assert_equal "hello from #{expected_name}", mod.message
  end
end
