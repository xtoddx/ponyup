module Ponyup
  module Components
    # see: {Ponyup::RakeDefinitions#domain}
    #
    # Does the heavy lifting for dealing with dns zones.
    #
    # :nodoc:
    #
    class Zone
      def initialize name, comment=nil
        @name = name
      end

      def create
        if record=cloud_resource
          converge_existing_resource(record)
        else
          record = create_new_resource
        end
      end

      def destroy
        if record=cloud_resource
          record.destroy
        end
      end

      def status
        if record=cloud_resource
          puts " up : zone:#{@name}"
        else
          puts "down: zone:#{@name}"
        end
      end

      private

      def resource_name
        "#{@name}#{Ponyup.resource_suffix}"
      end

      def cloud_resource
        Fog::DNS[:aws].zones.all.detect {|x| x.domain == @name }
      end

      def create_new_resource
        Fog::DNS[:aws].zones.create(domain: @name)
      end


      # Dumb old rake junk
      public

      extend Rake::DSL
      def self.define name, comment=nil
        instance = new(name, comment)
        namespace :dns do
          namespace name do
            instance_task "Create #{name} domain",
                          create: instance.method(:create)
            instance_task "Delete #{name} domain",
                          destroy: instance.method(:destroy)
            instance_task "Show status of #{name} domain",
                          status: instance.method(:status)
          end
        end
        "dns:#{name}"
      end

      def self.instance_task description, named_method
        desc description
        task(named_method.keys.first) { named_method.values.first.call }
      end
    end
  end
end
