Gem::Specification.new do |s|
  s.specification_version = 2
  s.required_rubygems_version = Gem::Requirement.new('>= 0')

  s.name = 'ponyup'
  s.version = '0.0.2'
  s.date = '2014-01-21'
  s.summary = 'Manage virtual machines from cloud setup to chef provisioning'
  s.description = 'Ponyup uses fog to manipulate clouds to get the them to the point you want use chef for provisioning, and then uses kinfe to bootstrap the nodes'
  s.authors = ['xtoddx']
  s.email = 'xtoddx@gmail.com'
  s.homepage = 'http://github.com/xtoddx/ponyup'
  s.license = 'MIT'
  s.require_paths = %w[lib]
  s.extra_rdoc_files = %w[README.md]

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {spec,tests}/*`.split("\n")

  s.add_dependency('fog', '>= 1.22.0')
  s.add_dependency('rake', '>= 10.1.1')
  s.add_dependency('chef', '>= 11.0.0')
  s.add_dependency('knife-solo', '>= 0.4.1')
end
