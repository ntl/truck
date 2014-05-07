module FakesFilesystem
  def before_setup
    super
    FakeFS::FileSystem.clear
    FakeFS.activate!
    World.build!
    monkeypatch_assert!
  end

  def after_teardown
    unmonkeypatch_assert!
    FakeFS.deactivate!
    super
  end

  private

  def monkeypatch_assert!
    Minitest::Assertions.module_eval do
      alias_method :orig_diff, :diff
      def diff(*args)
        FakeFS.without { orig_diff *args }
      end
    end
  end

  def unmonkeypatch_assert!
    Minitest::Assertions.module_eval do
      undef_method :diff
      alias_method :diff, :orig_diff
    end
  end

  module World
    extend self

    def build!
      Dir.mkdir '/foo'

      File.write "/foo/a.rb", <<-FILE
module A
  def self.message
    "hello from A"
  end

  def self.references_aa
    AA.message
  end

  def self.references_abracadabra
    Abracadabra.message
  end

  def self.references_caaa
    C::CA::CAA::CAAA.message
  end

  def self.references_z
    Z.message
  end

  module AB
    def self.message
      "hello from A::AB"
    end

    module ABA
      def self.message
        "hello from A::AB::ABA"
      end

      def self.references_abb
        ABB.message
      end
    end
  end
end
     FILE

     Dir.mkdir "/foo/a"
     File.write "/foo/a/aa.rb", <<-FILE
module A
  module AA
    def self.message
      "hello from A::AA"
    end
  end
end
      FILE

      Dir.mkdir "/foo/a/ab"
      File.write "/foo/a/ab/abb.rb", <<-FILE
module A
  module AB
    module ABB
      def self.message
        "hello from A::AB::ABB"
      end
    end
  end
end
      FILE

      Dir.mkdir "/foo/b"
      File.write "/foo/b/ba.rb", <<-FILE
module B
  module BA
    def self.message
      "hello from B::BA"
    end
  end
end
      FILE

      Dir.mkdir "/foo/c"
      Dir.mkdir "/foo/c/ca"
      Dir.mkdir "/foo/c/ca/caa"
      File.write "/foo/c/ca/caa/caaa.rb", <<-FILE
module C
  module CA
    module CAA
      module CAAA
        def self.message
          "hello from C::CA::CAA::CAAA"
        end
      end
    end
  end
end
      FILE

      File.write "/foo/d.rb", <<-FILE
class D
  def self.references_a
    A.message
  end
  def references_b_ba
    B::BA.message
  end
end
      FILE

      Dir.mkdir "/bar"
      File.write "/bar/a.rb", <<-FILE
module A
  def self.message
    "hello from Bar::A"
  end
end
      FILE

      File.write "/bar/b.rb", <<-FILE
module B
  def self.message
    "hello from Bar::B"
  end
end
      FILE

      File.write "/bar/z.rb", <<-FILE
module Z
  def self.message
    "hello from Bar::Z"
  end
end
      FILE

      Dir.mkdir "/my_app"
      Dir.mkdir "/my_app/lib"
      File.write "/my_app/lib/a.rb", <<-FILE
module A
  def self.message
    "hello from MyApp::A"
  end

  def self.references_b_ba
    B::BA.message
  end
end
      FILE

      File.write "/my_app/lib/includes_foo.rb", <<-FILE
class IncludesFoo
  include Foo

  def self.message
    D.new.references_b_ba
  end
end
      FILE

      Dir.mkdir "/my_app/lib/b"
      File.write "/my_app/lib/b/ba.rb", <<-FILE
module B
  module BA
    def self.message
      "hello from MyApp::B::BA"
    end
  end
end
      FILE

      File.write "/ext.rb", <<-FILE
class MyExtClass
  include Foo

  def message
    A.message
  end
end
      FILE
    end
  end
end
