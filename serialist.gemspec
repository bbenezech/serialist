# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{serialist}
  s.version = "1.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Benoit B\303\251n\303\251zech"]
  s.date = %q{2010-02-23}
  s.description = %q{Serialize any data, set and fetch it like any column attributes}
  s.email = %q{benoit.benezech@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "MIT-LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "generators/serialist/serialist_generator.rb",
     "generators/serialist/templates/USAGE",
     "generators/serialist/templates/migrate/serialist_migration.rb.erb",
     "init.rb",
     "install.rb",
     "installation-template.txt",
     "lib/serialist.rb",
     "lib/serialist/serialist_module.rb",
     "rails/init.rb",
     "serialist-1.3.0.gem",
     "serialist.gemspec",
     "tasks/acts_as_serializable_tasks.rake",
     "test/serialist_test.rb",
     "uninstall.rb"
  ]
  s.homepage = %q{http://github.com/bbenezech/serialist}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Serialize any data, set and fetch it like any column attributes}
  s.test_files = [
    "test/serialist_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

