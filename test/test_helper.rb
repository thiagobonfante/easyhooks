# Require and start simplecov BEFORE minitest/autorun loads ./lib to get correct test results.
# Otherwise lot of executed lines are not detected.
require 'simplecov'
SimpleCov.start do
  add_filter 'test'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('config/environment', __dir__)
require 'rails/test_help'

require 'minitest/autorun'
require 'active_job'
require 'active_record'
require 'mocha/minitest'
require 'easyhooks'

class << Minitest::Test
  def test(name, &block)
    test_name = :"test_#{name.gsub(' ','_')}"
    raise ArgumentError, "#{test_name} is already defined" if self.instance_methods.include? test_name.to_s
    if block
      define_method test_name, &block
    else
      puts "PENDING: #{name}"
    end
  end
end

class Order < ActiveRecord::Base
  easyhooks do
    action :submitted, fields: [:name] do
      # this trigger is using the default configuration
      trigger :my_default_trigger, method: :post, endpoint: 'https://easyhooks.io/my_default_trigger' do
        puts 'trigger block called'
      end
    end
  end
end

class Vendor < ActiveRecord::Base
  easyhooks do
    action :approved, fields: [:name] do
      trigger :my_yaml_trigger
      trigger :my_db_trigger, type: :stored
    end
  end
end

class User < ActiveRecord::Base
  easyhooks :stored do
    action :accepted, fields: [:name] do
      trigger :my_db_trigger end
  end
end

class BaseTest < Minitest::Test
  include ActiveJob::TestHelper
end


class ActiveRecordTestCase < BaseTest
  def exec(sql)
    ActiveRecord::Base.connection.execute sql
  end

  def seed_db
    exec "INSERT INTO orders(name, description) VALUES('some order', 'some description')"
    exec "INSERT INTO vendors(name, description) VALUES('some vendor', 'some description')"
    exec "INSERT INTO users(name, email) VALUES('some name', 'some@email.com')"
    exec "INSERT INTO easyhooks_stored_triggers(name, method, endpoint) VALUES('my_db_trigger', 'post', 'https://easyhooks.io/my_db_trigger')"
  end

  def clear_db
    Order.delete_all
    Vendor.delete_all
    Easyhooks::StoredTrigger.delete_all
  end

  def setup_db
    ActiveRecord::Base.establish_connection
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Schema.define(version: 1) do

      create_table :orders do |t|
        t.string :name, null: false
        t.string :description, null: false
      end

      create_table :vendors do |t|
        t.string :name, null: false
        t.string :description, null: false
      end

      create_table :users do |t|
        t.string :name, null: false
        t.string :email, null: false
      end
    end

    require 'easyhooks/migration'
    Easyhooks::Migration.up

    seed_db
  end

  def setup
    setup_db
  end

  def teardown
    ActiveRecord::Base.connection.disconnect!
  end

  def default_test
  end
end