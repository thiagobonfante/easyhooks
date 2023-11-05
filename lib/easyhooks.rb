# frozen_string_literal: true

begin
  require 'rubygems'
  require 'active_support'
  require 'active_record'
  require 'easyhooks/specification'
  ActiveRecord::Base

  module Easyhooks
    extend ActiveSupport::Concern
    module ClassMethods
      attr_reader :easyhooks_spec

      def easyhooks(&specification)
        assign_easyhooks Specification.new(self, &specification)
      end

      private

      def assign_easyhooks(specification_object)
        @easyhooks_spec = specification_object
      end
    end

    module InstanceMethods
      def hello
        puts 'hello'
      end

      def actions
        self.class.easyhooks_spec.actions
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
rescue LoadError
  # ActiveRecord is not available, do nothing or raise an error
  puts "error"
end
