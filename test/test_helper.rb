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

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def log_error(error)
    puts "Error: #{error}"
  end

  def log_any(message)
    puts "Any: #{message}"
  end
end

class Order < ApplicationRecord
  easyhooks method: :post, endpoint: 'https://easyhooks.io/my_default_action', auth: 'Bearer token', headers: { 'X-Easy': 'Easyhooks' }, payload: :payload do
    trigger :submitted do
      action :my_default_action
      action :my_other_action, if: :check_id, on_fail: :failed_action, method: :put do |response|
        if response.code == '200'
          log_any 'success'
        else
          log_any "failed with code: #{response.code}"
        end
      end
    end
  end

  def failed_action(error)
    log_error error
  end

  def payload
    {
      id: self.id,
      name: self.name,
      description: self.description,
      metadata: {
        count: Order.count
      }
    }
  end

  def check_id
    self.id == 2
  end
end

class Vendor < ActiveRecord::Base
  easyhooks do
    trigger :approved, on: %i[create update], only: %i[name] do
      action :my_yaml_action, method: 'PUT'
      action :my_db_action, type: :stored
    end
  end
end

class User < ActiveRecord::Base
  easyhooks :stored do
    trigger :deleted, on: %i[destroy] do
      action :my_db_action
    end
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
    exec "INSERT INTO easyhooks_store(context, name, method, endpoint) VALUES('triggers', 'my_db_action', 'post', 'https://easyhooks.io/my_db_action')"
    exec "INSERT INTO easyhooks_store_values(context, key, value, store_id) VALUES('auth', 'Bearer', 'token-db', 1)"
    exec "INSERT INTO easyhooks_store_values(context, key, value, store_id) VALUES('headers', 'X-DB', 'XX-DB-VALUE', 1)"
    exec "INSERT INTO easyhooks_store(context, name, method, endpoint) VALUES('User', 'my_db_action', 'post', 'https://easyhooks.io/my_db_action')"
  end

  def clear_db
    Order.delete_all
    Vendor.delete_all
    User.delete_all
    Easyhooks::Store.delete_all
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