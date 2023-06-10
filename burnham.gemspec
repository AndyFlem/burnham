# frozen_string_literal: true

require_relative "lib/burnham/version"

Gem::Specification.new do |spec|
  spec.name = "burnham"
  spec.version = Burnham::VERSION
  spec.authors = ["Andy Fleming"]
  spec.email = ["andy@ulendo.com"]

  spec.summary = "Burnham"
  spec.required_ruby_version = ">= 2.6.0"
  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["source_code_uri"] = "https://github.com/AndyFlem/burnham"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_dependency 'ruby-statistics'
  spec.add_dependency 'descriptive_statistics'
  spec.add_dependency 'caxlsx'
end
