# frozen_string_literal: true
require 'net/http'

module Easyhooks
  class PostProcessor < ActiveJob::Base
    queue_as :easyhooks

    def perform(klass_name, object_id, payload, action_name, action_trigger)
      init_data(klass_name, object_id, payload, action_name, action_trigger)
      begin
        request = create_http_request
        make_request(request)
        trigger_event
      rescue => e
        if @action.on_fail.present? && @object.respond_to?(@action.on_fail_callable)
          @object.send(@action.on_fail_callable, e)
        else
          raise e
        end
      end
    end

    private

    def init_data(klass_name, object_id, payload, action_name, action_trigger)
      @klass_name = klass_name
      @object = find_object(object_id)
      @action_trigger = action_trigger
      @action_name = action_name
      load_action_and_payload(payload)
    end

    def find_object(object_id)
      @klass = @klass_name.constantize
      @klass.find_by(id: object_id)
    end

    def json?(value)
      # check if value is a json string
      JSON.parse(value)
      true
    rescue JSON::ParserError
      false
    end

    def enrich_data(data)
      # if data is a hash or array or a json string
      default = {
        object: @klass_name,
        action: @action.name,
        trigger: {
          name: @action.trigger_name,
          event: @action_trigger.to_s.upcase
        }
      }
      if json?(data)
        default.merge({ data: JSON.parse(data) }).to_json
      else
        default.merge({ data: { id: data }}).to_json
      end
    end

    def load_action_and_payload(payload)
      @action = @klass.easyhooks_actions[@action_name]
      @action.load!(@klass_name)
      @payload = enrich_data(payload)
    end

    def create_http_request
      parsed_url = URI.parse(@action.hook.endpoint)
      host = parsed_url.host
      port = parsed_url.port
      raise "Unable to load endpoint: #{@action.hook.endpoint}" unless host.present? && port.present?

      @http = Net::HTTP.new(host, port)
      @http.use_ssl = true if parsed_url.scheme == 'https'

      Net::HTTP.const_get(@action.hook.method.to_s.capitalize).new(parsed_url.request_uri)
    end

    def make_request(request)
      request.body = @payload
      request.add_field('Content-Type', 'application/json')

      # add headers
      @action.hook.headers.each do |key, value|
        request.add_field(key, value)
      end

      # adds auth (bearer or basic)
      request.add_field('Authorization', @action.hook.auth) if @action.hook.auth.present?

      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.test? # disable SSL verification for test env
      @response = @http.request(request)
    end

    def trigger_event
      @object.send(@action.event_callable, @response) if @object.respond_to?(@action.event_callable)
    end
  end
end