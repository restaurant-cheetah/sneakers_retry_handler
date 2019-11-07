# frozen_string_literal: true

require File.expand_path('../lib/sneakers_handler/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'sneakers_handler'
  s.version     = SneakersHandler::VERSION
  s.platform    = Gem::Platform::RUBY
  s.licenses    = %w[MIT]
  s.authors     = ['Alex Stepanenko']
  s.email       = ['stepanenko.aleksander@gmail.com']
  s.summary     = 'Sneakers handler with delayed retrying'
  s.description = 'Retries in specified time interval. Supports `on_retry` and `on_error` callbacks'

  all_files  = `git ls-files`.split("\n")
  test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.files         = all_files - test_files
  s.test_files    = test_files
  s.require_paths = %w[lib]
end
