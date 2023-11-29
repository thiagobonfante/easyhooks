# frozen_string_literal: true

require "active_support/concern"

module Easyhooks
  module Validators
    extend ActiveSupport::Concern

    ALLOWED_ON_VALUES = %i[create update destroy].freeze
    ALLOWED_METHODS = %i[get post put patch delete].freeze
    ALLOWED_TYPES = %i[default stored].freeze

    included do
      def validate_type(type)
        return :default if type.nil?
        raise TypeError, "Invalid #{self.class} type: #{type}" unless ALLOWED_TYPES.include?(type)
        type
      end

      def validate_method(method)
        return nil if method.nil? && @type == :stored # this will be loaded by the processor
        return :post unless method.present?
        method = method.downcase if method.is_a?(String)
        raise TypeError, "Invalid method '#{method}' for #{self.class} '#{@name}'. Allowed values are: #{ALLOWED_METHODS}" unless ALLOWED_METHODS.include?(method.to_sym)
        method.to_sym
      end

      def valid_url?(url)
        URI.parse(url) rescue false
      end

      def validate_endpoint(endpoint)
        return nil if endpoint.nil? && @type == :stored # this will be loaded by the processor
        raise TypeError, "#{self.class} endpoint can't be nil" unless endpoint.present?
        raise TypeError, "#{self.class} endpoint is not a valid URL: #{endpoint}" unless valid_url?(endpoint)
        endpoint
      end

      def validate_name(name)
        raise TypeError, "#{self.class} name can't be nil" unless name.present?
        raise TypeError, "Invalid #{self.class} name '#{name}'. Name can only have alphanumeric characters and underscore" unless name =~ /\A[a-zA-Z0-9_]+\z/
        name
      end

      def validate_on(on)
        return ALLOWED_ON_VALUES if on.nil?
        on = [on] unless on.is_a?(Array)
        on.map do |value|
          raise TypeError, "Invalid attribute 'on' for #{self.class} #{@name}: #{on}. Allowed values are: #{ALLOWED_ON_VALUES}" unless ALLOWED_ON_VALUES.include?(value.to_sym)
          value
        end
      end

      def validate_only(only)
        return [] if only.nil?
        only = [only] unless only.is_a?(Array)
        only.map(&:to_sym) # convert only array into symbols array
      end

      def validate_callback(callback, attribute)
        if callback.nil? || callback.is_a?(Symbol) || callback.respond_to?(:call)
          callback
        else
          raise TypeError, "Invalid attribute '#{attribute}' for #{self.class} #{@name}: #{attribute} must be nil, an instance method name symbol or a callable (eg. a proc or lambda)"
        end
      end

      def validate_auth(auth)
        return nil if auth.nil?
        # validate if auth header is a string and it must be a Bearer token or a Basic auth to include into a HTTP request
        raise TypeError, "Invalid attribute 'auth_header' for #{self.class} #{@name}: #{auth} must be nil or a string" unless auth.is_a?(String)
        raise TypeError, "Invalid attribute 'auth_header' for #{self.class} #{@name}: #{auth} must be a Bearer token or a Basic auth" unless auth =~ /\ABearer\s/ || auth =~ /\ABasic\s/
        auth
      end

      def validate_headers(headers)
        return {} if headers.nil?
        headers = JSON.parse(headers.gsub(':', '').gsub('=>', ':')) if headers.is_a?(String)
        raise TypeError, "Invalid attribute 'headers' for #{self.class} #{@name}: #{headers} must be nil or a hash" unless headers.is_a?(Hash)
        headers
      end

      def validate_hook(hook)
        return hook if hook.nil? && @type == :stored
        hook.method = validate_method(hook.method)
        hook.endpoint = validate_endpoint(hook.endpoint)
        hook.auth = validate_auth(hook.auth)
        hook.headers = validate_headers(hook.headers)
        hook
      end
    end
  end
end