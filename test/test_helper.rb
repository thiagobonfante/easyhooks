# Require and start simplecov BEFORE minitest/autorun loads ./lib to get correct test results.
# Otherwise lot of executed lines are not detected.
require 'simplecov'
SimpleCov.start do
  add_filter 'test'
end

require 'minitest/autorun'
require 'active_job'
require 'active_record'
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

class BaseTest < Minitest::Test
  include ActiveJob::TestHelper
end

class ActiveRecordTestCase < BaseTest
  def exec(sql)
    ActiveRecord::Base.connection.execute sql
  end

  def setup
    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3",
      :database  => ":memory:" #"tmp/test"
    )
  end

  def teardown
    ActiveRecord::Base.connection.disconnect!
  end

  def default_test
  end
end