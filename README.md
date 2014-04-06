# Truck

Truck is an alternative autoloader that doesn't pollute the global namespace. Specifically, it does not load constants into `Object`; rather, it loads them into *Contexts* that you define. This has three main advantages:

1. `reload!` is very fast; `Object.send(:remove_const, :MyContext)` does the trick
2. You can have multiple autoloaders running in parallel contexts
3. Eliminates the need for `fork()` based preloaders like `zeus` and `spring`. Instead, load your gems, define your contexts, and safely `reload!` them between each test run.


## Installation

Add this line to your application's Gemfile:

    gem 'truck'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install truck

## Usage

Unlike ActiveSupport's autoloader, truck requires a bit of setup for each context. An example:

```ruby
Truck.define_context :MyContext, root: "/path/to/context/root"
```

Also, after defining all your contexts, you'll want to boot everyone up:

```ruby
Truck.boot!
```

You'll want to define all your contexts, then fork/spawn threads, then have every sub process invoke `Truck.boot!` separately.

### Referencing constants

Suppose you had a class called `Foo` living in `/path/to/context/root/foo.rb`:

```ruby
# /path/to/context/root/foo.rb
class Foo
  def self.bar
    Bar.hello_world
  end
end
```

```ruby
# /path/to/context/root/bar.rb
class Foo
  def self.hello_world
    "hello, world!"
  end
end
```

`Foo` can reference `Bar` without an explicit require. So how does the world outside of `MyContext` reference objects?

```ruby
MyContext.resolve_const("Bar")
```

This works with namespaced constant names, too:

```ruby
MyContext.resolve_const("Foo::Bar::Baz")
```

### Other

`MyContext` has some other interesting methods on it:

```ruby
# Wipe the whole context and reload it (also aliased as reload!)
MyContext.reset!

# Kill the context
MyContext.shutdown!

# Eagerly load the entire context into memory (good for production)
MyContext.eager_load!
```

These methods are also of course on `Truck` as well, and invoke the same operations on every context.

### Autoload Paths

By default, the `root` you pass to the `Context` is your autoload paths. You can alternatively supply a list of autoload paths relative to `root`:

```ruby
Truck.define_context(
  :MyContext,
  root: "/path/to/context/root",
  autoload_paths: %w(app/models app/controllers lib)
)
```

### Compatibiilty

Currently, truck has been tested against 2.1.1. It uses refinements internally. The plan is to support recent rubinius releases as well.

## Contributing

1. Fork it ( https://github.com/ntl/truck/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
