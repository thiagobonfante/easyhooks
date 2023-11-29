# frozen_string_literal: true

require 'easyhooks/concerns/helpers'
require 'easyhooks/concerns/validators'

module Easyhooks
  class Base
    include Easyhooks::Helpers
    include Easyhooks::Validators

    attr_accessor :name, :type, :hook, :condition, :payload, :on_fail

    def initialize(name, type, hook, condition, payload, on_fail)
      @name = validate_name(name)
      @type = validate_type(type)
      @hook = hook
      @condition = validate_callback(condition, 'if')
      @payload = validate_callback(payload, 'payload')
      @on_fail = validate_callback(on_fail, 'on_fail')
    end
  end
end
