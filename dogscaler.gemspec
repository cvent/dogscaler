# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |spec|
  spec.name          = "dogscaler"
  spec.version       = Dogscaler::VERSION
  spec.authors       = ["David Gibbons"]
  spec.email         = ["dgibbons@crowdcompass.com"]
  spec.summary       = %q{Autoscale groups based on datadog queries}
  spec.description   = %q{Autoscale aws groups based on datadog queries}
  spec.license       = "apache"
  spec.executables << 'dogscaler'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_dependency "thor", '~> 0.19'
  spec.add_dependency 'dogapi', '~> 1.23'
  spec.add_dependency 'virtus', '~> 1.0'
  spec.add_dependency 'facets', '~> 3.1'
  spec.add_dependency 'aws-sdk', '~> 2.6'
  spec.add_dependency 'json', '~> 2.0'

end
