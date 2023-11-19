# frozen_string_literal: true
require 'easyhooks/stored_trigger'

module Easyhooks
  class Trigger
    attr_accessor :name, :method, :endpoint, :type, :condition, :event_callable, :event

    def initialize(name, type, method, endpoint, condition, &event)
      @name = validate_name(name)
      @type = validate_type(type)
      @method = validate_method(method)
      @endpoint = validate_endpoint(endpoint)
      @condition = validate_condition(condition)
      @event_callable = "#{name}_event".to_sym
      @event = event
    end

    def reload!
      return if self.type == :default

      stored_trigger = StoredTrigger.find_by(name: self.name)

      raise "Trigger '#{self.name}' not found in database" unless stored_trigger.present?

      #noinspection RubyArgCount
      self.method = validate_method(stored_trigger.method)
      self.endpoint = validate_endpoint(stored_trigger.endpoint)
    end

    def condition_applicable?(object)
      if condition
        if condition.is_a?(Symbol)
          object.send(condition)
        else
          condition.call(object)
        end
      else
        true
      end
    end

    private

    ALLOWED_METHODS = %i[get post put patch delete].freeze
    ALLOWED_TYPES = %i[default stored].freeze

    def validate_name(name)
      raise "Trigger name can't be nil" unless name.present?
      raise "Invalid Trigger name: '#{name}'. Name can only have alphanumeric characters and underscore" unless name =~ /\A[a-zA-Z0-9_]+\z/
      name
    end

    def validate_type(type)
      return :default if type.nil?
      raise "Invalid Trigger type: #{type}" unless ALLOWED_TYPES.include?(type)
      type
    end

    def validate_method(method)
      return nil if method.nil? && @type == :stored # this will be loaded by the processor
      return :post unless method.present?
      raise "Invalid method '#{method}' for Trigger '#{@name}'. Allowed values are: #{ALLOWED_METHODS}" unless ALLOWED_METHODS.include?(method.to_sym)
      method.to_sym
    end

    def valid_url?(url)
      URI.parse(url) rescue false
    end

    def validate_endpoint(endpoint)
      return nil if endpoint.nil? && @type == :stored # this will be loaded by the processor
      raise "Trigger endpoint can't be nil" unless endpoint.present?
      raise "Trigger endpoint is not a valid URL: #{endpoint}" unless valid_url?(endpoint)
      endpoint
    end

    def validate_condition(condition)
      if condition.nil? || condition.is_a?(Symbol) || condition.respond_to?(:call)
        condition
      else
        raise TypeError, "Invalid attribute 'if' for Trigger #{@name}: condition must be nil, an instance method name symbol or a callable (eg. a proc or lambda)"
      end
    end
  end
end
