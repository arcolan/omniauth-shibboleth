# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth2-shibboleth/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_dependency 'omniauth', '~> 2.1.1'

  gem.add_development_dependency 'rack-test', '~> 2.1.0'
  gem.add_development_dependency 'rake', '~> 13.0.6'
  gem.add_development_dependency 'rspec', '~> 2.8'

  gem.license = 'MIT'

  gem.authors       = ["Sylvain Lanoë"]
  gem.email         = ["sylvain@arcolan.fr"]
  gem.description   = %q{OmniAuth Shibboleth strategies}
  gem.summary       = %q{OmniAuth Shibboleth strategies for OmniAuth 2.x}
  gem.homepage      = "https://rubygems.org/gems/omniauth2-shibboleth"

  gem.files         = `find . -not \\( -regex ".*\\.git.*" -o -regex "\\./pkg.*" -o -regex "\\./spec.*" \\)`.split("\n").map{ |f| f.gsub(/^.\//, '') }
  gem.test_files    = `find spec/*`.split("\n")
  gem.name          = "omniauth2-shibboleth"
  gem.require_paths = ["lib"]
  gem.version       = OmniAuth::Shibboleth::VERSION


end
