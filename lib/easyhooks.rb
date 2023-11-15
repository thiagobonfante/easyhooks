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

    def actions
      self.class.easyhooks_spec.actions.each do |action_name, action|
        puts "checking action: #{action_name}"
        action.fields.each do |field|
          puts "checking field: #{field}"
          if self.previous_changes.has_key?(field)
            puts "field changed: #{field}"
            action.triggers.each do |trigger|
              # serialize self to json and pass it to the post processor
              json = self.to_json
              PostProcessor.perform_later(self.class.name, json, trigger.name)
            end
          end
        end
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
