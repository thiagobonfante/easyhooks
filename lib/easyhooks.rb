# frozen_string_literal: true

require 'rubygems'
require 'rails'
require 'active_support'
require 'active_record'
require 'active_job'
require 'easyhooks/specification'
require 'easyhooks/post_processor'

module Easyhooks

  module ClassMethods
    attr_reader :easyhooks_spec

    def easyhooks(type = :default, &specification)
      assign_easyhooks Specification.new(type, &specification)
    end

    def easyhooks_triggers
      @easyhooks_spec.triggers
    end

    private

    def assign_easyhooks(specification_object)
      @easyhooks_spec = specification_object

      @easyhooks_spec.triggers.each do |_, trigger|
        module_eval do
          define_method trigger.event_callable do |response_data|
            instance_exec(response_data, &trigger.event)
          end
        end
      end
    end
  end

  module InstanceMethods
    extend ActiveSupport::Concern

    included do
      after_commit :actions
    end

    private

    def triggered_by
      return :create if self.transaction_include_any_action?([:create])

      return :update if self.transaction_include_any_action?([:update])

      return :destroy if self.transaction_include_any_action?([:destroy])

      :none
    end

    def perform_action_triggers(action)
      action.triggers.each do |trigger|
        next unless trigger.condition_applicable?(self)
        puts "performing trigger: #{trigger.name}"
        payload = triggered_by == :destroy ? { id: self.id }.to_json : self.to_json
        PostProcessor.perform_later(self.class.name, payload, trigger.name, triggered_by)
      end
    end

    def execute_action(action)
      return unless action.condition_applicable?(self)
      puts "executing action: #{action.name}"
      if action.only.empty? || triggered_by == :destroy
        perform_action_triggers(action)
      else
        action.only.each do |field|
          perform_action_triggers(action) if self.previous_changes.has_key?(field)
        end
      end
    end

    def actions
      self.class.easyhooks_spec.actions.each do |action_name, action|
        puts "checking action: #{action_name}"
        execute_action(action) if self.transaction_include_any_action?(action.on)
      end
    end
  end

  def self.included(klass)
    # check if the klass extends from ActiveRecord::Base, if not raise an error
    unless klass.ancestors.include?(ActiveRecord::Base)
      raise "Easyhooks can only be included in classes that extend from ActiveRecord::Base"
    end

    klass.send :include, InstanceMethods

    klass.extend ClassMethods
  end
end

ActiveRecord::Base.send(:include, Easyhooks)
