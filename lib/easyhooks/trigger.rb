# frozen_string_literal: true

module Easyhooks
  class Trigger
    attr_accessor :name, :block

    def initialize(name, &block)
      @name = name
      @block = block
    end
  end
end
