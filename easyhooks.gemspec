# frozen_string_literal: true

require_relative 'lib/easyhooks/version'

Gem::Specification.new do |gem|
  gem.name          = 'easyhooks'
  gem.version       = Easyhooks::VERSION
  gem.authors       = ['Thiago Bonfante']
  gem.email         = ['thiagobonfante@gmail.com']
  gem.description   = <<~DESC
    Easyhooks is a simple gem to create hooks in your code.
  DESC
  gem.summary       = 'Easyhooks'
  gem.licenses      = ['MIT']
  gem.homepage      = 'https://github.com/thiagobonfante/easy_hooks'

  gem.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.extra_rdoc_files = [
    'README.md'
  ]

  rails_versions = ['>= 6.0']

  gem.required_ruby_version = '>= 3.1'
  gem.add_runtime_dependency 'activerecord', rails_versions

  gem.add_development_dependency 'bundler',       '~> 2.0'
  gem.add_development_dependency 'minitest',      '~> 5.11'
  gem.add_development_dependency 'mocha',         '~> 1.8'
  gem.add_development_dependency 'rake',          '~> 12.3'
  gem.add_development_dependency 'rdoc',          '~> 6.1'
  gem.add_development_dependency 'sqlite3',       '~> 1.3'
end
