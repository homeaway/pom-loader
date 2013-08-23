# encoding: utf-8

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'pom-loader/version'

Gem::Specification.new do |s|
  s.name = 'pom-loader'
  s.version = PomLoader::VERSION
  s.authors = ['Matt Kinman', 'Patrick Ritchie', 'Michael May', 'Alan Scherger']
  s.email = 'mmay@homeaway.com'
  s.homepage = 'http://github.com/homeaway/pom-loader'
  s.summary = 'pom-loader - Loads maven poms into ruby context'
  s.description = 'Can interpret a maven pom and pull properties and classes into context.'

  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md']
  s.files = Dir['[A-Z]*', '{lib,spec}/**/*']
  s.test_files = Dir.glob('spec/**/*_spec.rb')
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.3.0'

  s.add_dependency 'nokogiri', '~> 1.5.0'
  s.add_development_dependency 'rake', '~> 10.0.0'
  s.add_development_dependency 'bundler', '~> 1.3.5'
  s.add_development_dependency 'rspec', '~> 2.13.0'
end
