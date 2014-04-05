require 'test_helper'

class AutoloaderTest < Minitest::Test
  include FakesFilesystem
  include TestsAutoloading

  def test_throws_constant_when_found
    const = assert_catches :const do
      Truck::Autoloader.handle :A, from: Foo
    end
    assert_equal 'Foo::A', const.name
  end

  def test_raises_error_when_const_not_found
    exception = assert_raises NameError do
      Truck::Autoloader.handle :Abracadabra, from: Foo
    end
    assert_equal 'uninitialized constant Abracadabra (in Foo)', exception.message
  end

  def test_simple_implicit_namespace_case
    Truck::Autoloader.handle :B, from: Foo
    const = assert_catches :const do
      Truck::Autoloader.handle :BA, from: Foo
    end
    assert_equal 'Foo::B::BA', const.name
    assert_nil Truck::Autoloader.current_autoloader
  end

  def test_cleanup_after_implicit_namespace
    Truck::Autoloader.handle :B, from: Foo
    assert_raises NameError do
      Truck::Autoloader.handle :Abracadabra, from: Foo
    end
    assert_nil Truck::Autoloader.current_autoloader
  end

  def test_deeply_nested_module_with_implicit_namespaces
    %i(C CA CAA).each do |implicit_namespace|
      Truck::Autoloader.handle implicit_namespace, from: Foo
    end
    const = assert_catches :const do
      Truck::Autoloader.handle :CAAA, from: Foo
    end
    assert_equal 'Foo::C::CA::CAA::CAAA', const.name
  end

  def test_shallowly_nested_module_with_implicit_namespaces
    @foo.resolve_const 'A::AB::ABA'

    const = assert_catches :const do
      Truck::Autoloader.handle :ABB, from: Foo::A::AB::ABA
    end
    assert_equal 'Foo::A::AB::ABB', const.name
  end

  private

  def assert_catches(thrown)
    val = catch thrown do
      yield
      :not_found
    end
    refute_equal :not_found, val, "Expected block to throw #{thrown.inspect}"
    val
  end

end
