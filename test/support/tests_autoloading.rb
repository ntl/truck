module TestsAutoloading
  def setup
    @foo = Truck.define_context :Foo, root: "/foo"
    @bar = Truck.define_context :Bar, root: '/bar', parent: :Foo
    @my_app = Truck.define_context :MyApp, root: "/my_app", autoload_paths: %w(lib)
    @multi = Truck.define_context :MultipleAutoloadPaths, root: "/", autoload_paths: %w(foo bar)
    @extend = Truck.define_context :Extend, root: "/extend", autoload_paths: %w(app lib)
    Truck.boot!
    assert_nil Truck::Autoloader.current_autoloader
  end

  def teardown
    assert_nil Truck::Autoloader.current_autoloader,
      "Each test in this file must clean up after itself"
  end
end
