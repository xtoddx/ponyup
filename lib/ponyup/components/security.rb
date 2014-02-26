module Ponyup
  module Components
    # see: {Ponyup::RakeDefinitions#security}
    #
    # Does the heavy lifing for working with security groups.
    #
    # :nodoc:
    #
    class Security
      def initialize name, public_ports=[], group_port_hash={}
        @name = name
        @public_ports = Array(public_ports)
        @group_ports = group_port_hash
      end

      def create
        if group=cloud_resource
          converge_existing_resource(group)
        else
          create_new_resource
        end
      end

      def destroy
        if group=cloud_resource
          group.delete
        end
      end

      private

      def resource_name
        "#{@name}#{Ponyup.resource_suffix}"
      end

      def cloud_resource
        Fog::Compute[:aws].security_groups.get(resource_name)
      end

      def create_new_resoruce
        group = Fog::Compute[:aws].security_groups.new(name: name,
                                          description: "#{name} [auto]")
        group.save
        add_ports_to_group group
      end

      def converge_existing_resource group
        delete_all_rules group
        add_ports_to_group group
      end

      def delete_all_rules group
        group.ip_permissions.each do |perm|
          ports = (perm['fromPort'] .. perm['toPort'])
          if perm['groups'].any?
            perm['groups'].each do |g|
              group_spec = {g['userId'] => g['groupId']}
              group.revoke_port_range(ports, group: group_spec)
            end
          else
            group.revoke_port_range(ports)
          end
        end
      end

      def add_ports_to_group group
        unless public_ports.empty?
          add_public_ports(group, public_ports)
        end
        unless group_ports.empty?
          group_ports.each do |extern_group, ports|
            ports = Array(ports)
            add_group_ports(group, extern_group, ports)
          end
        end
      end

      def add_public_ports group, ports
        ports.each do |range|
          range = range.respond_to?(:min) ? range : (range .. range)
          group.authorize_port_range(range)
        end
      end

      def add_group_ports group, other_name, ports
        other_name = "#{other_name}#{Ponyup.resource_suffix}"
        external_group = Fog::Compute[:aws].security_groups.get(other_name)
        aws_spec = {external_group.owner_id => external_group.name}
        ports.each do |port|
          range = port.respond_to?(:min) ? port : (port .. port)
          group.authorize_port_range range, group: aws_spec
        end
      end


      # JUNKY OLD RAKE STUFF
      public

      extend Rake::DSL

      # Return the namespace as string
      def self.define name, public_ports, group_ports
        instance = new(name, public_ports, group_ports)
        namespace :security do
          namespace name do
            instance_task "Create #{name} security group",
                          create: instance.method(:create)
            instance_task "Delete #{name} security group",
                          destroy: instance.method(:destroy)
          end
        end
        "security:#{name}"
      end

      private

      def self.instance_task description, named_method
        desc description
        task named_method.keys.first, &named_method.values.first
      end
    end
  end
end
