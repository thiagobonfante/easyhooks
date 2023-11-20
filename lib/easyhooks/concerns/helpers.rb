# frozen_string_literal: true

require "active_support/concern"

module Easyhooks
  module Helpers
    extend ActiveSupport::Concern

    included do
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

      def request_payload(object)
        if payload
          if payload.is_a?(Symbol)
            object.send(payload)
          else
            payload.call(object)
          end
        else
          { id: object.id }
        end
      end
    end
  end
end