# frozen_string_literal: true

require 'easyhooks/action'
require 'easyhooks/trigger'

module Easyhooks
  class Specification
    attr_accessor :actions

    def initialize(klass, &specification)
      @actions = {}
      instance_eval(&specification)
    end

    def action_names
      actions.keys
    end

    private

    def action(name, args, &triggers)
      new_action = Easyhooks::Action.new(name, args, &triggers)
      @actions[name] = new_action
      @scoped_action = new_action
      instance_eval(&triggers) if triggers
    end

    def trigger(name, &event)
      @scoped_action.triggers.push({ name: name, trigger: Easyhooks::Trigger.new(name, &event) })
    end
  end
end
