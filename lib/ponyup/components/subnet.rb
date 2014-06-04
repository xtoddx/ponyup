module Ponyup
  module Components
    # see: {Ponyup::RakeDefinitions#subnet}
    #
    # Does the heavy lifting for creating netwok infrastructure in a vpc.
    #
    # :nodoc:
    #
    class Subnet
      def initialize name, cidr, vpc_name
        @name = name
        @cidr = cidr
        @vpc_name = vpc_name
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
        Fog::Compute[:aws].subnets
      end

      def cloud_resource
        components.all('tag:Name' => resource_name,
                       'state' => 'available',
                       'vpc_id' => vpc_id).first
      end

      def create_new_resource
        components.create(cidr_block: @cidr,
                          tags: {'Name' => @name},
                          vpc_id: vpc_id)
      end

      def wait_for_ready resource
        resource.wait_for { ready? }
      end

      def vpc_id
        return nil unless @vpc_name
        Fog::Compute[:aws].vpc.all('tag:Name' => @vpc_name,
                                   'state' => 'available').first.id
      end


      # Dumb old rake junk
      public

      extend Rake::DSL
      def self.define name, cidr, vpc_name
        instance = new(name, cidr, vpc_name)
        namespace :subnet do
          namespace name do
            instance_task "Launch #{name}", create: instance.method(:create)
            instance_task "Terminate #{name}",
                          destroy: instance.method(:destroy)
            instance_task "Show status of #{name} host",
                          status: instance.method(:status)
          end
        end
        "subnet:#{name}"
      end

      def self.instance_task description, named_method
        desc description
        task(named_method.keys.first) { named_method.values.first.call }
      end
    end
  end
end
