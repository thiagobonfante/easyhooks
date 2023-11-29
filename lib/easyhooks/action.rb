# frozen_string_literal: true
require 'easyhooks/store'
require 'easyhooks/base'

module Easyhooks
  class Action < Easyhooks::Base

    attr_accessor :trigger_name, :args, :on_fail_callable, :event_callable, :event

    def initialize(name, trigger_name, hook, args = {}, &event)
      super(name, args[:type], hook, args[:if], args[:payload], args[:on_fail])
      @args = args
      @trigger_name = trigger_name
      @event_callable = "#{name}_event".to_sym
      @on_fail_callable = "#{name}_on_fail".to_sym
      @event = event
      @hook = validate_hook(hook)
    end

    def load!(klass_name = nil)
      return if self.type == :default

      stored_action = Store.find_by(name: self.name, context: 'actions')
      stored_action ||= Store.find_by(name: self.trigger_name, context: 'triggers')
      stored_action ||= Store.find_by(name: klass_name, context: 'classes') if klass_name.present?
      stored_action ||= Store.find_by(name: self.name, context: 'global')

      raise "Action '#{self.name}' not found in database" unless stored_action.present?

      # noinspection RubyArgCount
      self.hook.method = validate_method(stored_action.method)
      self.hook.endpoint = validate_endpoint(stored_action.endpoint)
      self.hook.auth = validate_auth(stored_action.auth)
      self.hook.headers = validate_headers(stored_action.headers)
    end
  end
end
