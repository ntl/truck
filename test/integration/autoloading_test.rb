require 'test_helper'

class AutoloadingTest < Minitest::Test
  include FakesFilesystem
  include TestsAutoloading

  def test_simple_case
    assert_equal 'hello from A::AA', Foo::A.references_aa
  end

  def test_negative_case
    assert_raises NameError do
      Foo::A.references_abracadabra
    end
  end

  def test_deeply_nested_module_with_implicit_namespaces
    assert_equal 'hello from C::CA::CAA::CAAA', Foo::A.references_caaa
  end

  def test_reference_from_within_constant
    assert_equal 'hello from A', Foo::D.references_a
    assert_equal 'hello from B::BA', Foo::D.new.references_b_ba
  end

  def test_invoking_method_inside_implicit_namespace_raises_error
    exception = assert_raises NameError do
      Foo::C.hello
    end
    assert_equal "uninitialized constant C (in Foo)", exception.message
  end

  def test_raises_name_error_if_no_context_found
    exception = assert_raises NameError do
      Abracadabra
    end
    assert_equal "uninitialized constant Abracadabra", exception.message
  end

  def test_explicit_autoload_paths
    assert_equal 'hello from Bar::Z', MultipleAutoloadPaths::A.references_z
  end

  def test_reference_constants_in_included_class
    assert_equal 'hello from B::BA', MyApp::IncludesFoo.message
  end
end
