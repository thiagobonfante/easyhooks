# frozen_string_literal: true

require 'easyhooks/action'
require 'easyhooks/trigger'

module Easyhooks
  class Specification
    attr_accessor :type, :actions, :triggers

    def initialize(type = :default, &specification)
      @type = type
      @actions = {}
      @triggers = {}
      instance_eval(&specification)
    end

    def action_names
      actions.keys
    end

    private

    def action(name, args, &triggers)
      new_action = Easyhooks::Action.new(name, args[:on], args[:only], args[:if], &triggers)
      @actions[name] = new_action
      @scoped_action = new_action
      instance_eval(&triggers) if triggers
    end

    def trigger(name, args = {}, &event)
      type = args[:type] || @type || :default
      method = config_lookup(name, type, args, :method)&.downcase&.to_sym
      endpoint = config_lookup(name, type, args, :endpoint)
      new_trigger = Easyhooks::Trigger.new(name, type, method, endpoint, args[:if], &event)
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

      raise ":#{value} configuration not specified for action: #{action_name}, trigger: #{trigger_name}"
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
