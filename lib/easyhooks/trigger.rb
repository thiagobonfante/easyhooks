# frozen_string_literal: true
require 'easyhooks/stored_trigger'

module Easyhooks
  class Trigger
    attr_accessor :name, :method, :endpoint, :type, :event

    # validate the method on initialization
    def validate_trigger_method(method)
      raise "Invalid method: #{method}" unless %w[GET POST PUT PATCH DELETE].include?(method.upcase) if method.present?
      method
    end

    def initialize(name, method, endpoint, type, &event)
      @name = name
      @method = validate_trigger_method(method)
      @endpoint = endpoint
      @type = type
      @event = event
    end

    def reload!
      return if self.type == :default

      stored_trigger = StoredTrigger.find_by(name: self.name)
      if stored_trigger.present?
        #noinspection RubyArgCount
        self.method = stored_trigger.method
        self.endpoint = stored_trigger.endpoint
      end
    end
  end
end
