# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'truck/version'

Gem::Specification.new do |spec|
  spec.name          = "truck"
  spec.version       = Truck::VERSION
  spec.authors       = ["ntl"]
  spec.email         = ["nathanladd+github@gmail.com"]
  spec.summary       = %q{Truck is an alternative autoloader that doesn't pollute the global namespace. Specifically, it does not load constants into `Object`; rather, it loads them into *Contexts* that you define.}
  spec.description   = %q{Truck is an alternative autoloader that doesn't pollute the global namespace.}
  spec.homepage      = "https://github.com/ntl/truck"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "fakefs", "~> 0.5"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.0"
  spec.add_development_dependency "rake", "~> 10.0"
end
