lib = "pay4bugs-hooks"
lib_file = File.expand_path("../lib/#{lib}.rb", __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = $1
sha = `git rev-parse HEAD 2>/dev/null || echo unknown`
sha.chomp!
version << ".#{sha[0,7]}"

Gem::Specification.new do |spec|
  spec.specification_version = 2 if spec.respond_to? :specification_version=
  spec.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if spec.respond_to? :required_rubygems_version=

  spec.name    = lib
  spec.version = version

  spec.summary = "Pay4Bugs Hooks client code"

  spec.authors  = ["Larry Salibra"]
  spec.email    = 'larry@appartisan.com'
  spec.homepage = 'https://github.com/pay4bugs/pay4bugs-hooks'
  spec.licenses = ['MIT']

  spec.add_dependency "addressable",            "~> 2.2.7"
  spec.add_dependency 'yajl-ruby',              '1.1.0'
  spec.add_dependency "mash",                   "~> 0.1.1"
  spec.add_dependency "mime-types",             "~> 1.15"
  spec.add_dependency "ruby-hmac",              "0.4.0"
  spec.add_dependency "faraday",                "0.7.6"

  # Basecamp Classic
  spec.add_dependency "activeresource",         "~> 3.2.13"

  # Twitter
  spec.add_dependency "oauth",                  "0.4.4"

 

  spec.files = %w(Gemfile LICENSE README.mkdn CONTRIBUTING.md Rakefile)
  spec.files << "#{lib}.gemspec"
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("test/**/*.rb")
  spec.files += Dir.glob("script/*")

  dev_null    = File.exist?('/dev/null') ? '/dev/null' : 'NUL'
  git_files   = `git ls-files -z 2>#{dev_null}`
  spec.files &= git_files.split("\0") if $?.success?
end
