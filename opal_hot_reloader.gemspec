# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opal_hot_reloader/version'

Gem::Specification.new do |spec|
  spec.name          = "opal_hot_reloader"
  spec.version       = OpalHotReloader::VERSION
  spec.authors       = ["Forrest Chang"]
  spec.email         = ["fchang@hedgeye.com"]

  spec.summary       = %q{Opal Hot reloader}
  spec.description   = %q{Opal Hot Reloader with reactrb suppot}
  spec.homepage      = "https://github.com/fkchang/opal_hot_reloader"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "opal-rspec", "~> 0.5.0"
  

  spec.add_dependency 'listen', '~> 3.0'
  spec.add_dependency 'websocket'
end
