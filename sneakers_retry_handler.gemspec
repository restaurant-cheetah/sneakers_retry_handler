# frozen_string_literal: true

require File.expand_path('../lib/sneakers_retry_handler', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'sneakers_retry_handler'
  s.version     = SneakersRetryHandler::VERSION
  s.platform    = Gem::Platform::RUBY
  s.licenses    = %w[MIT]
  s.authors     = ['Ivan Bondarenko', 'Alex Stepanenko']
  s.email       = ['bondarenko.dev@gmail.com', 'stepanenko.aleksander@gmail.com']
  s.summary     = 'Sneakers handler with delayed retrying'
  s.description = 'Retries in specified time interval. Supports `on_retry` and `on_error` callbacks'
  s.homepage = 'https://github.com/restaurant-cheetah/sneakers_retry_handler'

  s.add_development_dependency 'json', '~> 2.2'
  s.add_development_dependency 'pry', '~> 0.12'
  s.add_development_dependency 'rspec', '~> 3.9'
  s.add_development_dependency 'sneakers', '~> 2.11'

  all_files  = `git ls-files`.split("\n")
  test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.files         = all_files - test_files
  s.test_files    = test_files
  s.require_paths = %w[lib]
end
