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

    def easyhooks(type = :default, args = {}, &specification)
      if type.is_a?(Hash)
        args = type
        type = :default
      end
      # get self.class replacing :: from the module::class name with _
      # e.g. MyModule::MyClass becomes MyModule_MyClass
      klass_name = self.name.to_s.gsub('::', '_')
      assign_easyhooks Specification.new(klass_name, type, args, &specification)
    end

    def easyhooks_actions
      @easyhooks_spec.actions
    end

    private

    def assign_easyhooks(specification_object)
      @easyhooks_spec = specification_object

      @easyhooks_spec.actions.each do |_, action|
        module_eval do
          define_method action.event_callable do |response_data|
            instance_exec(response_data, &action.event) if action.event.present?
          end

          define_method action.on_fail_callable do |error|
            send(action.on_fail, error)
          end
        end
      end
    end
  end

  module InstanceMethods
    extend ActiveSupport::Concern

    included do
      after_commit :triggers
    end

    private

    def triggered_by
      return :create if self.transaction_include_any_action?([:create])

      return :update if self.transaction_include_any_action?([:update])

      return :destroy if self.transaction_include_any_action?([:destroy])

      :none
    end

    def perform_trigger_actions(trigger)
      trigger.actions.each do |action|
        next unless action.condition_applicable?(self)
        puts "performing action: #{action.name}"
        payload = action.request_payload(self).to_json
        PostProcessor.perform_later(self.class.name, self.id, payload, action.name, triggered_by)
      end
    end

    def execute_trigger(trigger)
      return unless trigger.condition_applicable?(self)
      puts "executing trigger: #{trigger.name}"
      if trigger.only.empty? || triggered_by == :destroy
        perform_trigger_actions(trigger)
      else
        trigger.only.each do |field|
          perform_trigger_actions(trigger) if self.previous_changes.has_key?(field)
        end
      end
    end

    def triggers
      self.class.easyhooks_spec.triggers.each do |trigger_name, trigger|
        puts "checking trigger: #{trigger_name}"
        execute_trigger(trigger) if self.transaction_include_any_action?(trigger.on)
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
