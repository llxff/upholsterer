# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'upholsterer/version'

Gem::Specification.new do |s|
  s.name        = 'upholsterer'
  s.version     = Upholsterer::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Aleksandr Fomin']
  s.email       = ['ll.wg.bin@gmail.com']
  s.homepage    = 'https://github.com/llxff/upholsterer'
  s.summary     = 'A simple serializer implementation.'
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split($/).map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry-meta'
  s.add_dependency 'activesupport'
end
