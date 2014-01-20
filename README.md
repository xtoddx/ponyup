# Pony Up
A friendly DSL on top of [Rake](rake) to define and launch your cloud services.
Uses [Fog](fog) to talk to the cloud.

This is all for AWS right now.

# Philosophy
* Infrastructure as code
* Start with basic building blocks: security groups, hosts, etc
* Everything at a higher level can be done by chef
* Provide the transition from lower layer (fog) to apps (chef)

# Example

Rakefile:

    require_relative 'lib/ponyup'

    security 'web', [80, 8080]

    host 'appserver', 'web', 'recipe[appserver]'

    task :default => :ponyup
