module Ponyup
  module Components
    # see: {Ponyup::RakeDefinitions#vpc}
    #
    # Does the heavy lifting for dealing with vpc.
    #
    # :nodoc:
    #
    class Vpc
      def initialize name, cidr
        @name = name
        @cidr = cidr
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
        Fog::Compute[:aws].vpcs
      end

      def cloud_resource
        components.all('tag:Name' => resource_name,
                       'state' => 'available').first
      end

      def create_new_resource
        component = components.create(cidr_block: @cidr)
        component.service.create_tags(component.id, {'Name' => @name})
        component
      end

      def wait_for_ready resource
        resource.wait_for { ready? }
      end


      # Dumb old rake junk
      public

      extend Rake::DSL
      def self.define name, cidr
        instance = new(name, cidr)
        namespace :vpc do
          namespace name do
            instance_task "Launch #{name}", create: instance.method(:create)
            instance_task "Terminate #{name}",
                          destroy: instance.method(:destroy)
            instance_task "Show status of #{name} host",
                          status: instance.method(:status)
          end
        end
        "vpc:#{name}"
      end

      def self.instance_task description, named_method
        desc description
        task(named_method.keys.first) { named_method.values.first.call }
      end
    end
  end
end
