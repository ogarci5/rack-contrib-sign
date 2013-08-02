# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/contrib/sign/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-contrib-sign"
  spec.version       = Rack::Contrib::Sign::VERSION
  spec.authors       = ["Graham Christensen"]
  spec.email         = ["info@zippykid.com"]
  spec.description   = %q{Implement secure API request igning.}
  spec.summary       = %q{Validates headers and API keys in Authorization}
  spec.homepage      = "https://github.com/zippykid/rack-contrib-sign"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency('guard')
  spec.add_development_dependency('guard-rspec')

end

