# frozen_string_literal: true
require 'easyhooks/stored_trigger'
require 'easyhooks/concerns/helpers'
require 'easyhooks/concerns/validators'

module Easyhooks
  class Trigger
    include Easyhooks::Helpers
    include Easyhooks::Validators

    attr_accessor :name, :action_name, :method, :endpoint, :type, :condition, :payload, :on_fail, :on_fail_callable, :event_callable, :event

    def initialize(name, action_name, type, method, endpoint, condition, payload, on_fail, &event)
      @name = validate_name(name)
      @action_name = action_name
      @type = validate_type(type)
      @method = validate_method(method)
      @endpoint = validate_endpoint(endpoint)
      @condition = validate_callback(condition, 'condition')
      @payload = validate_callback(payload, 'payload')
      @on_fail = validate_callback(on_fail, 'on_fail')
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
