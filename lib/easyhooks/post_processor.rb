# frozen_string_literal: true
require 'net/http'

module Easyhooks
  class PostProcessor < ActiveJob::Base
    queue_as :easyhooks

    def perform(klass_name, payload, trigger_name, action_trigger)
      puts "Performing #{klass_name} #{trigger_name} #{action_trigger}"

      init_data(klass_name, payload, trigger_name, action_trigger)
      load_trigger(klass_name, trigger_name)
      load_http_request
      make_request
      trigger_event
    end

    private

    def init_data(klass_name, payload, trigger_name, action_trigger)
      @klass_name = klass_name
      @action_trigger = action_trigger
      @trigger_name = trigger_name
      @payload = enrich_data(payload)
    end

    def enrich_data(data)
      {
        action: "ON_#{@action_trigger.to_s.upcase}",
        object: @klass_name,
        data: JSON.parse(data)
      }.to_json
    end

    def load_trigger(klass_name, trigger_name)
      @klass = klass_name.constantize
      @trigger = @klass.easyhooks_triggers[trigger_name]
      @trigger.reload!
    end

    def load_http_request
      parsed_url = URI.parse(@trigger.endpoint)
      host = parsed_url.host
      port = parsed_url.port
      raise "Unable to load endpoint: #{@trigger.endpoint}" unless host.present? && port.present?

      @http = Net::HTTP.new(host, port)
      @http.use_ssl = true if parsed_url.scheme == 'https'

      # instantiate Net::HTTP::Get, Net::HTTP::Post, etc., based on the trigger method
      @request = Net::HTTP.const_get(@trigger.method.to_s.capitalize).new(parsed_url.request_uri)
    end

    def make_request
      @request.body = @payload
      @request['Content-Type'] = 'application/json'
      @response = @http.request(@request)
    end

    def trigger_event
      payload_object = JSON.parse(@payload)
      object = @klass.find_by(id: payload_object['data']['id'])
      object.send(@trigger.event_callable, @response) if object.respond_to?(@trigger.event_callable)
    end
  end
end