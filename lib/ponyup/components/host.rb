module Ponyup
  module Components
    # see: {Ponyup::RakeDefinitions#host}
    #
    # Does the heavy lifting for dealing with hosts.
    #
    # :nodoc:
    #
    class Host
      def initialize name, security_groups, _runlist, options
        @name = name
        security_groups = Array(security_groups)
        @groups = security_groups.map {|x| "#{x}#{Ponyup.resource_suffix}" }
        @options = options
      end

      def create
        if host=cloud_resource
          converge_existing_resource(host)
        else
          create_new_resource
        end
        wait_for_ready
      end

      def destroy
        if host=cloud_resource
          host.destroy
        end
      end

      private

      def resource_name
        "#{@name}#{Ponyup.resource_suffix}"
      end

      def cloud_resource
        Fog::Compute[:aws].servers.all('tag:Name' => name,
                                       'instance-state-name' => 'running').first
      end

      def create_new_resource
        key = options[:key_name] || Fog.credentials[:key_name]
        size = options[:size] || Fog.credentials[:size]
        image = options[:image_id] || Fog.credentials[:image_id]
        Fog::Compute[:aws].servers.create(groups: security_groups,
                                          key_name: key,
                                          flavor_id: size,
                                          image_id: image,
                                          tags: {'Name' => name})
      end

      def wait_for_ready
        host = cloud_resource
        Fog.wait_for { server.reload ; server.ready? }
      end


      # Dumb old rake junk
      public

      extend Rake::DSL
      def self.define name, security_groups, _runlist=[], options={}
        instance = new(name, security_groups, _runlist, options)
        namespace :host do
          namespace name do
            instance_task "Launch #{name}", create: instance.method(:create)
            instance_task "Terminate #{name}",
                          destroy: instance.method(:destroy)
          end
        end
        "host:#{name}"
      end

      def self.instance_task description, named_method
        desc description
        task named_method.keys.first, &named_method.values.first
      end
    end
  end
end
