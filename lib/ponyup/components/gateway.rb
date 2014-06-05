module Ponyup
  module Components
    # see: {Ponyup::RakeDefinitions#gateway}
    #
    # Does the heavy lifting for mapping subnets to internets.
    #
    # :nodoc:
    #
    class Gateway
      def initialize name, vpc_name
        @name = name
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
        Fog::Compute[:aws].internet_gateways
      end

      def vpc_id
        return nil unless @vpc_name
        @vpc_id ||= Fog::Compute[:aws].vpcs.all('tag:Name' => @vpc_name,
                                                state: :available).first.id
      end

      def cloud_resource
        components.all('tag:Name' => resource_name).first
      end

      def create_new_resource
        gateway = components.create
        if vpc_id
          gateway.attach(vpc_id)
        end
        gateway.service.create_tags gateway.id, {'Name' => @name}
        gateway
      end

      def wait_for_ready resource
        true
      end


      # Dumb old rake junk
      public

      extend Rake::DSL
      def self.define name, vpc_name
        instance = new(name, vpc_name)
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
