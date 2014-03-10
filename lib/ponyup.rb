require 'fog'

module Ponyup
  class << self
    attr_accessor :resource_suffix
  end
  self.resource_suffix = ''

  autoload :RakeDefinitions, 'ponyup/rake_definitions'
  autoload :Runner, 'ponyup/runner'

  module Components
    autoload :Security, 'ponyup/components/security'
    autoload :Host, 'ponyup/components/host'
  end

  module Provisioners
    autoload :KnifeSolo, 'ponyup/provisioners/knife_solo'
  end
end

# Include the defintions at the top level for Rakefiles.
include Ponyup::RakeDefinitions
