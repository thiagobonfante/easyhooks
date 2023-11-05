# frozen_string_literal: true
require 'net/http'

module Easyhooks
  class PostProcessor < ActiveJob::Base
    queue_as :easyhooks

    def perform(klass_name, json, trigger_name)
      klass = klass_name.constantize
      trigger = klass.easyhooks_triggers[trigger_name]
      trigger.event.call

      parsed_url = URI.parse(trigger.endpoint)
      http = Net::HTTP.new(parsed_url.host, parsed_url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(parsed_url.request_uri)
      request.body = json
      request['Content-Type'] = 'application/json'
      response = http.request(request)
      puts response.body
    end
  end
end