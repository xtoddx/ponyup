# Ponyup Example: Chef Server

The first thing you probably want to do in the cloud is run a chef server that
all your instances launched in the future can connect to. This is that initail
step.

### Requirements

* knife-solo, bootstraps the server node w/o an existing chef server
* berkshelf, for specifying cookbooks in a plaintext format

### Running

    rake [FOG_CREDENTIAL=staging]

