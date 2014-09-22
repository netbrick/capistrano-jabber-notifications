# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "capistrano-jabber-notifications"
  spec.version       = '0.3.0'
  spec.authors       = ["Pavel Lazureykis", "NetBrick"]
  spec.email         = ["lazureykis@gmail.com", "info@netbrick.eu", "jan.strnadek@gmail.com"]
  spec.description   = %q{Sending notifications about deploy to jabber}
  spec.summary       = %q{Sending notifications about deploy to jabber}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'xmpp4r', '~> 0.5'
  spec.add_dependency 'capistrano', '~> 3.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
