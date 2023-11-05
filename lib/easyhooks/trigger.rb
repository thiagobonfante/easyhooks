# frozen_string_literal: true

module Easyhooks
  class Trigger
    attr_accessor :name, :method, :endpoint, :event

    def initialize(name, method, endpoint, &event)
      @name = name
      @method = method
      @endpoint = endpoint
      @event = event
    end
  end
end
