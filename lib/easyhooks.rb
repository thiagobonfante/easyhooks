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
        puts "performing trigger: #{trigger.name}"
        # serialize self to json and pass it to the post processor
        json = self.to_json
        PostProcessor.perform_later(self.class.name, json, trigger.name, triggered_by)
      end
    end

    def execute_action(action)
      puts "executing action: #{action.name}"
      if action.only.empty?
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
        # action.on.each do |on|
        #   puts "checking on: #{on}"
        #   # create a switch case for on checking values create update destroy
        #   case on
        #   when :create, transaction_include_any_action?([:create])
        #     perform_action_triggers(action)
        #   when :update
        #     # check if self has just updated
        #     if
        #     if action.only.empty?
        #       trigger_all(action)
        #     else
        #       action.only.each do |field|
        #         trigger_all(action) if self.previous_changes.has_key?(field)
        #       end
        #     end
        #   end
        #   when :destroy
        #     puts "got destroy"
        #   else
        #     puts "got else default"
        #   end
        # end
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
