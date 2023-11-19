# frozen_string_literal: true

module Easyhooks
  class Action
    attr_accessor :name, :on, :only, :condition, :triggers

    def initialize(name, on, only, condition)
      @name = validate_name(name)
      @on = validate_on(on)
      @only = validate_only(only)
      @condition = validate_condition(condition)
      @triggers = []
    end

    def add_trigger(trigger)
      @triggers.push(trigger)
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

    ALLOWED_ON_VALUES = %i[create update destroy].freeze

    def validate_name(name)
      raise TypeError, "Action name can't be nil" unless name.present?
      raise TypeError, "Invalid Action name '#{name}'. Name can only have alphanumeric characters and underscore" unless name =~ /\A[a-zA-Z0-9_]+\z/
      name
    end

    def validate_on(on)
      return ALLOWED_ON_VALUES if on.nil? || on.empty?
      on = on.map(&:to_sym) # convert on array into symbols array
      on.map do |value|
        raise TypeError, "Invalid attribute 'on' for Action #{@name}: #{on}. Allowed values are: #{ALLOWED_ON_VALUES}" unless ALLOWED_ON_VALUES.include?(value.to_sym)
        value.to_sym
      end
    end

    def validate_only(only)
      return [] if only.nil? || only.empty?
      only.map(&:to_sym) # convert only array into symbols array
    end

    def validate_condition(condition)
      if condition.nil? || condition.is_a?(Symbol) || condition.respond_to?(:call)
        condition
      else
        raise TypeError, "Invalid attribute 'if' for Action #{@name}: condition must be nil, an instance method name symbol or a callable (eg. a proc or lambda)"
      end
    end
  end
end
