# frozen_string_literal: true
require 'net/http'

module Easyhooks
  class PostProcessor < ActiveJob::Base
    queue_as :easyhooks

    def perform(klass_name, object_id, payload, trigger_name, action_trigger)
      puts "Performing #{klass_name} #{trigger_name} #{action_trigger}"

      init_data(klass_name, object_id, payload, trigger_name, action_trigger)
      begin
        request = create_http_request
        make_request(request)
        trigger_event
      rescue => e
        if @trigger.on_fail.present? && @object.respond_to?(@trigger.on_fail_callable)
          @object.send(@trigger.on_fail_callable, e)
        else
          raise e
        end
      end
    end

    private

    def init_data(klass_name, object_id, payload, trigger_name, action_trigger)
      @klass_name = klass_name
      @object = find_object(object_id)
      @action_trigger = action_trigger
      @trigger_name = trigger_name
      load_trigger_and_payload(payload)
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
        event: @action_trigger.to_s.upcase,
        action: @trigger.action_name,
        trigger: @trigger.name,
        object: @klass_name,
      }
      if json?(data)
        default.merge({ data: JSON.parse(data) }).to_json
      else
        default.merge({ data: { id: data }}).to_json
      end
    end

    def load_trigger_and_payload(payload)
      @trigger = @klass.easyhooks_triggers[@trigger_name]
      @trigger.load!
      @payload = enrich_data(payload)
    end

    def create_http_request
      parsed_url = URI.parse(@trigger.endpoint)
      host = parsed_url.host
      port = parsed_url.port
      raise "Unable to load endpoint: #{@trigger.endpoint}" unless host.present? && port.present?

      @http = Net::HTTP.new(host, port)
      @http.use_ssl = true if parsed_url.scheme == 'https'

      # instantiate Net::HTTP::Get, Net::HTTP::Post, etc., based on the trigger method
      Net::HTTP.const_get(@trigger.method.to_s.capitalize).new(parsed_url.request_uri)
    end

    def make_request(request)
      request.body = @payload
      request.add_field('Content-Type', 'application/json')

      # add headers
      @trigger.headers.each do |key, value|
        request.add_field(key, value)
      end

      # adds auth (bearer or basic)
      request.add_field('Authorization', @trigger.auth) if @trigger.auth.present?

      @response = @http.request(request)
    end

    def trigger_event
      @object.send(@trigger.event_callable, @response) if object.respond_to?(@trigger.event_callable)
    end
  end
end