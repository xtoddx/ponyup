require 'fog'

module Ponyup
  class << self
    attr_accessor :resource_suffix
  end
  self.resoruce_suffix = ''

  autoload RakeDefinitions, 'ponyup/rake_definitions'
  autoload Runner, 'ponyup/runner'

  module Components
    autoload Security, 'ponyup/components/security'
    autoload Host, 'ponyup/components/host'
  end
end

# Include the defintions at the top level for Rakefiles.
include Ponyup::RakeDefinitions
