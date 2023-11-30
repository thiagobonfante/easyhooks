# frozen_string_literal: true

require_relative 'lib/easyhooks/version'

Gem::Specification.new do |gem|
  gem.name          = 'easyhooks'
  gem.version       = Easyhooks::VERSION
  gem.authors       = ['Thiago Bonfante']
  gem.email         = ['thiagobonfante@gmail.com']
  gem.description   = <<~DESC
    Easyhooks is a simple gem to that allows you to create hooks in your ActiveRecord models.
  DESC
  gem.summary       = 'Easyhooks'
  gem.licenses      = ['Apache-2.0']
  gem.homepage      = 'https://github.com/thiagobonfante/easyhooks'

  gem.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.extra_rdoc_files = [
    'README.md'
  ]

  rails_versions = ['>= 6.0']

  gem.required_ruby_version = '>= 3.1'
  gem.add_runtime_dependency 'rails', rails_versions
  gem.add_runtime_dependency 'activerecord', rails_versions
  gem.add_runtime_dependency 'activejob', rails_versions

  gem.add_development_dependency 'bundler',       '~> 2.0'
  gem.add_development_dependency 'minitest',      '~> 5.20.0'
  gem.add_development_dependency 'mocha',         '~> 2.1.0'
  gem.add_development_dependency 'rake',          '~> 12.3'
  gem.add_development_dependency 'rdoc',          '~> 6.1'
  gem.add_development_dependency 'sqlite3',       '~> 1.3'
end
