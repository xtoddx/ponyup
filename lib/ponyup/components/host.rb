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
          host = create_new_resource
        end
        wait_for_ready host
      end

      def destroy
        if host=cloud_resource
          host.destroy
        end
      end

      def status
        if host=cloud_resource
          puts " up : host:#{@name} #{host.dns_name}"
        else
          puts "down: host:#{@name}"
        end
      end

      private

      def resource_name
        "#{@name}#{Ponyup.resource_suffix}"
      end

      def components
        Fog::Compute[:aws].servers
      end

      def cloud_resource
        components.all('tag:Name' => resource_name,
                       'instance-state-name' => 'running',
                       'vpc-id' => vpc_id).first
      end

      def create_new_resource
        key = @options[:key_name] || Fog.credentials[:key_name]
        size = @options[:size] || Fog.credentials[:size]
        image = @options[:image_id] || Fog.credentials[:image_id]
        components.create(groups: @groups,
                          key_name: key,
                          flavor_id: size,
                          image_id: image,
                          subnet_id: subnet_id,
                          tags: {'Name' => @name})
      end

      def wait_for_ready host
        Fog.wait_for { host.reload ; host.ready? }
      end

      def subnet
        return nil unless @options[:subnet]
        @subnet ||= Fog::Compute[:aws].subnets.all(
                        'tag:Name' => @options[:subnet]).first
      end

      def subnet_id
        subnet ? subnet.subnet_id : nil
      end

      def vpc_id
        return nil unless subnet
        subnet.vpc_id
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
            instance_task "Show status of #{name} host",
                          status: instance.method(:status)
          end
        end
        "host:#{name}"
      end

      def self.instance_task description, named_method
        desc description
        task(named_method.keys.first) { named_method.values.first.call }
      end
    end
  end
end
