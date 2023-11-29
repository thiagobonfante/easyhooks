# frozen_string_literal: true

module Easyhooks
  class Hook
    ATTRIBUTES = [:method, :endpoint, :auth, :headers]
    attr_accessor(*ATTRIBUTES)
  end
end
