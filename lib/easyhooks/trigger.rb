# frozen_string_literal: true

require 'easyhooks/base'

module Easyhooks
  class Trigger < Easyhooks::Base

    attr_accessor :args, :on, :only, :actions

    def initialize(name, hook, args = {})
      super(name, args[:type], hook, args[:if], args[:payload], args[:on_fail])
      @args = args
      @on = validate_on(args[:on])
      @only = validate_only(args[:only])
      @actions = []
    end

    def add_action(action)
      @actions.push(action)
    end
  end
end
