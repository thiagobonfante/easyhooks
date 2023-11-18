# frozen_string_literal: true

module Easyhooks
  class Action
    attr_accessor :name, :on, :only, :triggers

    def initialize(name, on, only, &triggers)
      @name = validate_name(name)
      @on = validate_on(on)
      @only = validate_only(only)
      @triggers = []
    end

    private

    ALLOWED_ON_VALUES = %i[create update destroy].freeze

    def validate_name(name)
      raise "Action name can't be nil" unless name.present?
      raise "Invalid Action name '#{name}'. Name can only have alphanumeric characters and underscore" unless name =~ /\A[a-zA-Z0-9_]+\z/
      name
    end

    def validate_on(on)
      return ALLOWED_ON_VALUES if on.nil? || on.empty?
      on = on.map(&:to_sym) # convert on array into symbols array
      on.map do |value|
        raise "Invalid attribute 'on' for Action #{@name}: #{on}. Allowed values are: #{ALLOWED_ON_VALUES}" unless ALLOWED_ON_VALUES.include?(value.to_sym)
        value.to_sym
      end
    end

    def validate_only(only)
      return [] if only.nil? || only.empty?
      only.map(&:to_sym) # convert only array into symbols array
    end
  end
end
