
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "news2kindle/version"

Gem::Specification.new do |spec|
  spec.name          = "news2kindle"
  spec.version       = News2kindle::VERSION
  spec.authors       = ["TADA Tadashi"]
  spec.email         = ["t@tdtds.jp"]

  spec.summary       = %q{scrape some news site and deliver to kindle}
  spec.description   = %q{scrape some news site and deliver to kindle}
  spec.homepage      = "https://github.com/tdtds/news2kindle"
  spec.license       = "GPL"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'kindlegen'
  spec.add_dependency 'systemu'
  spec.add_dependency 'mail'
  spec.add_dependency 'mechanize'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'dropbox_api'
  spec.add_dependency 'mongoid', '~> 6.1'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
