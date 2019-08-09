# -*- encoding: utf-8 -*-
# stub: dry-inflector 0.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-inflector".freeze
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luca Guidi".freeze, "Andrii Savchenko".freeze, "Abinoam P. Marques Jr.".freeze]
  s.bindir = "exe".freeze
  s.date = "2018-04-25"
  s.description = "String inflections for dry-rb".freeze
  s.email = ["me@lucaguidi.com".freeze, "andrey@aejis.eu".freeze, "abinoam@gmail.com".freeze]
  s.homepage = "http://dry-rb.org".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "DRY Inflector".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.16"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.50.0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.16"])
      s.add_dependency(%q<rake>.freeze, ["~> 12.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.50.0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.16"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.50.0"])
  end
end
