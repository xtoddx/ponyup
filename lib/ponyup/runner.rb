module Ponyup
  # Provides the `ponyup`/`ponydown` tasks for top-level entrypoints.
  #
  # Also provides a simple way for other tasks to register themselves as a
  # prerequisite during both up and down actions.
  #
  # :nodoc:
  #
  class Runner
    extend Rake::DSL
    def self.add_component namespace
      task 'ponyup' => "#{namespace}:create"
      task 'ponydown' => "#{namespace}:destroy"
    end

    def self.add_setup_task action
      task 'ponyup' => action
    end

    def self.add_teardown_task action
      task 'ponydown' => action
    end
  end
end
