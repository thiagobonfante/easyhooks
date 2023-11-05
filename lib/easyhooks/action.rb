# frozen_string_literal: true

module Easyhooks
  class Action
    attr_accessor :name, :fields, :triggers

    def initialize(name, fields, &triggers)
      @name = name
      @fields = fields
      @triggers = []
    end

    def name
      @name
    end
  end
end
