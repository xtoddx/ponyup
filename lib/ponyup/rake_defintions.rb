module Ponyup
  module RakeDefinitions
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
      Ponyup::SecurityRecord.define name, public_ports, group_ports
      Ponyup::Runner.add_component "security:#{name}"
    end

    # Define a server.
    #
    # Options: key_name, image_id, size, knife_solo, attributes (filename)
    #
    def host name, security_groups, runlist, options={}
      HostRecord.define name, security_groups, runlist, options
      Ponyup::Runner.add_component "host:#{name}"
    end

    # Define a process for configuring server.
    #
    # See the provisioner docs for argument list.
    #
    def provision hostname, provisioner, *provisioner_args
      Ponyup::Provisioner.define hostname, provisioner, *provisioner_args
      Ponyup::Runner.add_setup_task "host:#{hostname}:provision"
    end
  end
