# frozen_string_literal: true

require 'easyhooks/action'
require 'easyhooks/trigger'

module Easyhooks
  class Specification
    attr_accessor :actions, :triggers

    def initialize(&specification)
      @actions = {}
      @triggers = {}
      instance_eval(&specification)
    end

    def action_names
      actions.keys
    end

    private

    def action(name, args, &triggers)
      new_action = Easyhooks::Action.new(name, args[:fields], &triggers)
      @actions[name] = new_action
      @scoped_action = new_action
      instance_eval(&triggers) if triggers
    end

    def trigger(name, args, &event)
      new_trigger = Easyhooks::Trigger.new(name, args[:method], args[:endpoint], &event)
      @triggers[name] = new_trigger
      @scoped_trigger = new_trigger
      @scoped_action.triggers.push(new_trigger)
    end
  end
end
