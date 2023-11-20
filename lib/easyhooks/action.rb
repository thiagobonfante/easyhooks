# frozen_string_literal: true

require 'easyhooks/base'

module Easyhooks
  class Action < Easyhooks::Base

    attr_accessor :on, :only, :triggers

    def initialize(name, on, only, condition, payload, on_fail, auth = nil, headers = {})
      super(name, condition, payload, on_fail, auth, headers)
      @on = validate_on(on)
      @only = validate_only(only)
      @triggers = []
    end

    def add_trigger(trigger)
      @triggers.push(trigger)
    end
  end
end
