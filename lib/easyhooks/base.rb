# frozen_string_literal: true

require 'easyhooks/concerns/helpers'
require 'easyhooks/concerns/validators'

module Easyhooks
  class Base
    include Easyhooks::Helpers
    include Easyhooks::Validators

    attr_accessor :name, :condition, :payload, :on_fail, :auth, :headers

    def initialize(name, condition, payload, on_fail, auth = nil, headers = {})
      @name = validate_name(name)
      @condition = validate_callback(condition, 'if')
      @payload = validate_callback(payload, 'payload')
      @on_fail = validate_callback(on_fail, 'on_fail')
      @auth = validate_auth(auth)
      @headers = validate_headers(headers)
    end
  end
end
