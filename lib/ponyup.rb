require 'fog'

Fog.credential = (ENV['FOG_CREDENTIAL'] || :staging).to_sym

# Define a security group.
#
# To define a group that allows public access:
#
#     security 'vulnerable', [22, 80]
#     security 'webish', 443
#
# To define an internal network accessible by instances on other groups:
#
#     security 'shadows', [], vulnerable: [22]
#     security 'shadows', nil, vulnerable: 22
#
# To define a group that allows both public and internal net traffic:
#
#     security 'hybrid', 22, shadows: 8080
#     security 'hybrid', [22, 80], shadows: 8080
#
def security name, public_ports=[], group_ports={}
  security_namespace = SecurityRecord.define name, public_ports, group_ports
  CloudRunner.add_component security_namespace
end

# Define a server.
#
# Options: key_name, image_id, size, knife_solo, attributes (filename)
#
def host name, security_groups, runlist, options={}
  host_namespace = HostRecord.define name, security_groups, runlist
  CloudRunner.add_component host_namespace
end

class CloudRunner # :nodoc:
  extend Rake::DSL
  def self.add_component namespace
    task 'ponyup' => "#{namespace}:create"
    task 'ponydown' => "#{namespace}:destroy"
  end
end

class SecurityRecord # :nodoc:
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
    owner_id = external_group.owner_id
    aws_sepc = {owner_id => external_group.to_s}
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
          owner_id = Fog::Compute[:aws].security_groups.get(g).owner_id
          group.revoke_group_and_owner(g, owner_id)
        end
      else
        group.revoke_port_range(ports)
      end
    end
  end
end

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
    instance = get_instance(name)
    key_name = options[:key_name] || Fog.credentials[:key_name]
    if options[:knife_solo]
      system "knife solo bootstrap ubuntu@#{instance.dns_name} " +
             "#{options[:attributes]}" +
             "--identity-file ~/.ssh/#{key_name}.pem --node-name #{name}" +
             "--run-list #{runlist}"
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
