# frozen_string_literal: true

require 'easyhooks/concerns/helpers'
require 'easyhooks/concerns/validators'

module Easyhooks
  class Action
    include Easyhooks::Helpers
    include Easyhooks::Validators

    attr_accessor :name, :on, :only, :condition, :payload, :on_fail, :triggers

    def initialize(name, on, only, condition, payload, on_fail)
      @name = validate_name(name)
      @on = validate_on(on)
      @only = validate_only(only)
      @condition = validate_callback(condition, 'condition')
      @payload = validate_callback(payload, 'payload')
      @on_fail = validate_callback(on_fail, 'on_fail')
      @triggers = []
    end

    def add_trigger(trigger)
      @triggers.push(trigger)
    end
  end
end
