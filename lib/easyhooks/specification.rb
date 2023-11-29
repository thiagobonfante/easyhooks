# frozen_string_literal: true

require 'easyhooks/action'
require 'easyhooks/trigger'
require 'easyhooks/hook'
require 'easyhooks/concerns/helpers'
require 'easyhooks/concerns/validators'

module Easyhooks
  class Specification
    include Easyhooks::Helpers
    include Easyhooks::Validators

    attr_accessor :name, :type, :global_args, :actions, :triggers, :scoped_action, :scoped_trigger

    def initialize(name, type, args = {}, &specification)
      @name = name
      @type = type
      @global_args = args.merge({ type: type })
      @triggers = {}
      @actions = {}
      instance_eval(&specification)
    end

    private

    def trigger(name, args = {}, &actions)
      # merge args with global args keeping args as the priority
      args = @global_args.merge(args)

      type = args[:type]

      hook_definition = find_trigger_hook(name, type, args)

      # create the trigger
      new_trigger = Easyhooks::Trigger.new(name, hook_definition, args)
      @triggers[name] = new_trigger
      @scoped_trigger = new_trigger
      instance_eval(&actions) if actions
    end

    def action(name, args = {}, &event)
      args = @scoped_trigger.args.merge(args)
      type = args[:type]

      hook_definition = find_action_hook(name, type, args)

      # create the action
      new_action = Easyhooks::Action.new(name, @scoped_trigger.name, hook_definition, args, &event)
      @actions[name] = new_action
      @scoped_action = new_action
      @scoped_trigger.add_action(new_action)
    end

    def find_trigger_hook(name, type, args)
      hook_definition = Hook.new
      Hook::ATTRIBUTES.each do |field|
        value = hook_lookup(:triggers, name, type, args, field) || hook_lookup(:classes, @name, type, args, field)
        hook_definition.send("#{field}=".to_sym, value)
      end
      hook_definition
    end

    def find_action_hook(name, type, args)
      hook_definition = Hook.new
      Hook::ATTRIBUTES.each do |field|
        value = hook_lookup(:actions, name, type, args, field) || @scoped_trigger.hook.send(field) || hook_lookup(:global, name, type, args, field)
        hook_definition.send("#{field}=".to_sym, value)
      end
      hook_definition
    end

    def hook_lookup(attr_type, attr_name, type, args, field)
      # stored triggers will load at post processor time
      return nil if type == :stored

      if args.present?
        value = args[field]&.to_s
        return value if value.present?
      end

      if config_file_exists? && [:method, :endpoint, :auth].include?(field)
        value = config.dig(Rails.env, attr_type.to_s, attr_name.to_s, field.to_s)&.to_s
        return value if value.present?
      end

      if config_file_exists? && field == :headers
        value = config.dig(Rails.env, attr_type.to_s, attr_name.to_s, field.to_s)&.to_h
        return value if value.present?
      end

      # return nil unless attr_type == :triggers
      #
      # raise ArgumentError, "Attribute :#{field} not found for #{attr_type}::#{attr_name}" if [:method, :endpoint].include?(field)
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
