# frozen_string_literal: true
require 'easyhooks/stored_trigger'
require 'easyhooks/base'

module Easyhooks
  class Trigger < Easyhooks::Base

    attr_accessor :action_name, :method, :endpoint, :type, :on_fail_callable, :event_callable, :event

    def initialize(name, action_name, type, method, endpoint, condition, payload, on_fail, auth = nil, headers = {}, &event)
      super(name, condition, payload, on_fail, auth, headers)
      @action_name = action_name
      @type = validate_type(type)
      @method = validate_method(method)
      @endpoint = validate_endpoint(endpoint)
      @event_callable = "#{name}_event".to_sym
      @on_fail_callable = "#{name}_on_fail".to_sym
      @event = event
    end

    def load!
      return if self.type == :default

      stored_trigger = StoredTrigger.find_by(name: self.name)

      raise "Trigger '#{self.name}' not found in database" unless stored_trigger.present?

      #noinspection RubyArgCount
      self.method = validate_method(stored_trigger.method)
      self.endpoint = validate_endpoint(stored_trigger.endpoint)
    end
  end
end
