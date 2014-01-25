# Pony Up
A friendly DSL on top of [Rake][rake] to define and launch your cloud services.
Uses [Fog][fog] to talk to the cloud.

This is all for AWS right now.

# Philosophy
* Infrastructure as code
* Start with basic building blocks: security groups, hosts, etc
* Everything at a higher level can be done by chef
* Provide the transition from lower layer (fog) to apps (chef)

# Overview

### ~/.fog

First, set up your ~/.fog file with credentials and defaults:

    :production:
      :aws_access_key_id: XXXXXXXXXXXXXXXXX
      :aws_secret_access_key: XXXXXXXXXXXXXXXXXX
      :region: us-east-1
      :key_name: production
      :image_id: ami-9b85eef2
      :flavor_id: t1.micro

Your key_name field should have a matching ~/.ssh/{key_name}.pem file. If you
name the group in fog anything other than `default` you will need to use the
FOG_CREDENTIAL environment variable when running rake.


### Rakefile

    require_relative 'lib/ponyup'

    security 'web', [80, 8080]

    host 'appserver', 'web', 'recipe[appserver]'

    task :default => :ponyup

### Invocation

To set up your full set of hosts and security groups:

    rake FOG_CREDENTIAL=production

To tear down your server:

    rake host:appserver:destroy [FOG_CREDENTIAL=...]

To see all availabe tasks:

    rake -D

# Examples

There are examples in the [examples/][examples] directory.

[fog]: http://fog.io/
[rake]: http://rake.rubyforge.org/
[examples]: http://github.com/xtoddx/ponyup/tree/master/examples
