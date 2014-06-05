module Ponyup
  module Components
    # see: {Ponyup::RakeDefinitions#routes}
    #
    # Set up routing rules for VPC subnets.
    #
    # :nodoc:
    #
    class Routes
      # Possible options:
      #
      # :gateway: name of the gateway to route through
      #
      def initialize name, vpc_name, options={}
        @name = name
        @vpc = cidr
        @options = options
      end

      def create
        if resource=cloud_resource
          converge_existing_resource(resource)
        else
          resource = create_new_resource
        end
        wait_for_ready resource
      end

      def destroy
        if resource=cloud_resource
          resource.destroy
        end
      end

      def status
        if resource=cloud_resource
          puts " up : #{component_name}:#{@name}"
        else
          puts "down: #{component_name}:#{@name}"
        end
      end

      private

      def resource_name
        "#{@name}#{Ponyup.resource_suffix}"
      end

      def component_name
        self.class.name.split('::').last
      end

      def components
        Fog::Compute[:aws].route_tables
      end

      def vpc_id
        @vpc_id ||= Fog::Compute[:aws].vpcs.all('tag:Name' => @vpc,
                                                state: :available).first.id

      def cloud_resource
        components.all('tag:Name' => resource_name, 'vpc-id' => vpc_id).first
      end

      def create_new_resource
        resource = components.create(vpc_id: vpc_id, tags: {'Name' => @name})
        if @options[:gateway]
          # TODO: make this happen
        end
        resource
      end

      def wait_for_ready resource
        resource.wait_for { ready? }
      end


      # Dumb old rake junk
      public

      extend Rake::DSL
      def self.define name, cidr
        instance = new(name, cidr)
        namespace :gateway do
          namespace name do
            instance_task "Launch #{name}", create: instance.method(:create)
            instance_task "Terminate #{name}",
                          destroy: instance.method(:destroy)
            instance_task "Show status of #{name} host",
                          status: instance.method(:status)
          end
        end
        "gateway:#{name}"
      end

      def self.instance_task description, named_method
        desc description
        task(named_method.keys.first) { named_method.values.first.call }
      end
    end
  end
end
