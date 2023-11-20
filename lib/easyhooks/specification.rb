# frozen_string_literal: true

require 'easyhooks/action'
require 'easyhooks/trigger'
require 'easyhooks/concerns/helpers'
require 'easyhooks/concerns/validators'

module Easyhooks
  class Specification
    include Easyhooks::Helpers
    include Easyhooks::Validators

    attr_accessor :type, :actions, :triggers, :method, :endpoint, :scoped_action, :on_fail, :scoped_trigger

    def initialize(type, args = {}, &specification)
      @type = type
      @global_args = args
      @method = args[:method]
      @endpoint = args[:endpoint]
      @actions = {}
      @triggers = {}
      instance_eval(&specification)
    end

    def action_names
      actions.keys
    end

    private

    def action(name, args = {}, &triggers)
      # search and collect existing arguments
      on = args[:on] || validate_on(@global_args[:on])
      only = args[:only] || validate_only(@global_args[:only])
      condition = args[:if] || validate_callback(@global_args[:if], 'if')
      payload = args[:payload] || validate_callback(@global_args[:payload], 'payload')
      on_fail = args[:on_fail] || validate_callback(@global_args[:on_fail], 'on_fail')
      auth = args[:auth] || validate_auth(@global_args[:auth])
      headers = args[:headers] || validate_headers(@global_args[:headers])

      # create the action
      new_action = Easyhooks::Action.new(name, on, only, condition, payload, on_fail, auth, headers)
      @actions[name] = new_action
      @scoped_action = new_action
      instance_eval(&triggers) if triggers
    end

    def trigger(name, args = {}, &event)
      # search and collect existing arguments
      type = args[:type] || validate_type(@type)
      method = config_lookup(name, type, args, :method)&.downcase&.to_sym
      endpoint = config_lookup(name, type, args, :endpoint)
      payload = args[:payload] || @scoped_action.payload
      on_fail = args[:on_fail] || @scoped_action.on_fail
      auth = args[:auth] || @scoped_action.auth
      headers = args[:headers] || @scoped_action.headers

      # create the trigger
      new_trigger = Easyhooks::Trigger.new(name, @scoped_action.name, type, method, endpoint, args[:if], payload, on_fail, auth, headers, &event)
      @triggers[name] = new_trigger
      @scoped_trigger = new_trigger
      @scoped_action.add_trigger(new_trigger)
    end

    def names
      action_name = @scoped_action.name
      trigger_name = @scoped_trigger.name
      [action_name, trigger_name]
    end

    def config_lookup(trigger_name, type, args, field)
      # stored triggers will load at post processor time
      return nil if type == :stored

      if args.present?
        value = args[field]&.to_s
        return value if value.present?
      end

      value = Rails.application.credentials.dig(:easyhooks, trigger_name, field)&.to_s
      return value if value.present?

      if config_file_exists?
        value = config.dig(Rails.env, trigger_name.to_s, field.to_s)&.to_s
        return value if value.present?
      end

      value = self.send(field)
      return self.send("validate_#{field}".to_sym, value) if value.present?

      raise ":#{field} configuration not specified for action: #{@scoped_action.name}, trigger: #{trigger_name}"
    end

    def config_file_exists?
      @config_file_exists ||= File.exist?(config_file)
    end

    def config_file
      args = 'config', 'easyhooks.yml'
      args.unshift('test') if Rails.env.test?

      @config_file ||= File.join(Rails.root, args)
    end

    def config
      @config ||= YAML.load_file(config_file)
    end
  end
end
