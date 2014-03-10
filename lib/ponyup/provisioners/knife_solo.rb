module Ponyup
  module Provisioners
    class KnifeSolo
      # Options:
      #   :key_name: ssh key name (located as ~/.ssh/#{key_name}.pem, uses
      #              Fog.credentials[:key_name] as default
      #   :username: defaults to ubuntu
      #   :attrubite_file: file to load attributes from, default=nil
      #   :config_file: knife config, default's to knife's list
      #   :runlist: array of runlist items, default: nil (specified by config)
      #
      def initialize hostname, options
        @hostname = hostname
        @options = options
      end

      def provision
        host = cloud_resource
        key_name = @options[:key_name] || Fog.credentials[:key_name]
        username = @options[:username] || 'ubuntu'
        attributes = @options[:attributes]
        config_file = @options[:config_file]
        runlist = @options[:runlist]
        system "knife solo bootstrap #{username}@#{host.dns_name} " +
               "#{attributes if attributes} " +
               "#{"--config #{config_file}" if config_file} " +
               "--identity-file ~/.ssh/#{key_name}.pem " +
               "--forward-agent --sudo-command \"sudo -E\" " +
               "#{"--run-list #{@runlist.join(',')}" if @runlist}"
      end

      private

      def resource_name
        "#{@hostname}#{Ponyup.resource_suffix}"
      end

      def cloud_resource
        Fog::Compute[:aws].servers.all('tag:Name' => resource_name,
                                       'instance-state-name' => 'running').first
      end

      public

      extend Rake::DSL
      def self.define hostname, options={}
        knife = new(hostname, options)
        namespace :host do
          namespace hostname do
            instance_task "Provision #{hostname} with knife-solo",
                          provision: knife.method(:provision)
          end
        end
        "host:#{hostname}:provision"
      end

      def self.instance_task description, named_method
        desc description
        task(named_method.keys.first) { named_method.values.first.call }
      end
    end
  end
end

=begin
          system "knife bootstrap #{instance.dns_name} " +
                 "--identity-file ~/.ssh/#{key_name}.pem --forward-agent " +
                 "--ssh-user ubuntu --sudo --node-name #{name} " +
                 "--run-list #{runlist}"
=end
