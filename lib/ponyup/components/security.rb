module Ponyup
  module Components
    # see: {Ponyup::RakeDefinitions#security}
    #
    # Does the heavy lifing for working with security groups.
    #
    # :nodoc:
    #
    class SecurityRecord
      extend Rake::DSL

      # Return the namespace as string
      def self.define name, public_ports, group_ports
        namespace :security do
          namespace name do
            desc "Create #{name} security group"
            task :create do
              SecurityRecord.create name, public_ports, group_ports
            end

            desc "Delete #{name} security group"
            task :destroy do
              SecurityRecord.destroy name
            end
          end
        end
        "security:#{name}"
      end

      def self.create name, public_ports, group_ports
        public_ports = Array(public_ports)
        group = Fog::Compute[:aws].security_groups.get(name)
        if group
          delete_all_rules(group)
        else
          group = Fog::Compute[:aws].security_groups.new(name: name,
                                            description: "Autmated Group #{name}")
          group.save
        end
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

      def self.destroy name, ports
        if group=Fog::Compute[:aws].security_groups.get(name)
          group.delete
        end
      end

      def self.add_public_ports group, ports
        ports.each do |range|
          range = range.respond_to?(:min) ? range : (range .. range)
          group.authorize_port_range(range)
        end
      end

      def self.add_group_ports group, other_name, ports
        external_group = Fog::Compute[:aws].security_groups.get(other_name)
        aws_spec = {external_group.owner_id => external_group.name}
        ports.each do |port|
          range = port.respond_to?(:min) ? port : (port .. port)
          group.authorize_port_range range, group: aws_spec
        end
      end

      def self.delete_all_rules group
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
    end
  end
end
