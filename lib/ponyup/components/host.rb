module Ponyup
  module Components
    # see: {Ponyup::RakeDefinitions#host}
    #
    # Does the heavy lifting for dealing with hosts.
    #
    # :nodoc:
    #
    class HostRecord # :nodoc:
      extend Rake::DSL

      def self.define name, security_groups, runlist=[], options={}
        namespace :host do
          namespace name do
            desc "Launch #{name} in the cloud"
            task :spinup do
              HostRecord.launch name, security_groups, options
            end

            desc "Provision #{name} with chef"
            task :provision do
              HostRecord.provision name, runlist, options
            end

            desc "Create #{name} host"
            task :create => [:spinup, :provision]

            desc "Delete #{name} security group"
            task :destroy do
              HostRecord.destroy name
            end
          end
        end
        "host:#{name}"
      end

      def self.launch name, security_groups, options
        if existing=get_instance(name)
          existing.destroy
        end
        key = options[:key_name] || Fog.credentials[:key_name]
        size = options[:size] || Fog.credentials[:size]
        image = options[:image_id] || Fog.credentials[:image_id]
        server = Fog::Compute[:aws].servers.create(groups: security_groups,
                                                   key_name: key,
                                                   flavor_id: size,
                                                   image_id: image,
                                                   tags: {'Name' => name})
        Fog.wait_for { server.reload ; server.ready? }
      end

      def self.provision name, runlist, options
        return if runlist.to_s.empty? && !options[:knife_solo]
        instance = get_instance(name)
        key_name = options[:key_name] || Fog.credentials[:key_name]
        if options[:knife_solo]
          system "knife solo bootstrap ubuntu@#{instance.dns_name} " +
                 "#{options[:attributes]} " +
                 "--identity-file ~/.ssh/#{key_name}.pem --node-name #{name} " +
                 "--forward-agent --sudo-command \"sudo -E\" " +
                 "#{"--run-list #{runlist}" if runlist}"
        else
          system "knife bootstrap #{instance.dns_name} " +
                 "--identity-file ~/.ssh/#{key_name}.pem --forward-agent " +
                 "--ssh-user ubuntu --sudo --node-name #{name} " +
                 "--run-list #{runlist}"
        end
      end

      def self.destroy name
        get_instance(name).destroy
      end

      def self.get_instance name
        Fog::Compute[:aws].servers.all('tag:Name' => name,
                                       'instance-state-name' => 'running').first
      end
    end
  end
end
