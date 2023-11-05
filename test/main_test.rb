require File.join(File.dirname(__FILE__), 'test_helper')

ActiveRecord::Migration.verbose = false

class Order < ActiveRecord::Base
  include Easyhooks
  easyhooks do
    action :submitted, fields: [:name] do
      trigger :accept do
        puts 'accept'
      end
    end
  end
end

class MainTest < ActiveRecordTestCase

  def setup
    super

    ActiveRecord::Schema.define do
      create_table :orders do |t|
        t.string :name, null: false
        t.string :description, null: false
      end
    end

    exec "INSERT INTO orders(name, description) VALUES('some order', 'some description')"
  end

  test 'should include an order and check that sqlite is working' do
    o = Order.all.first
    assert 'some order', o.name
  end

  test 'should raise exception when include easyhooks without active record' do
    error = assert_raises RuntimeError do
      class NotActiveRecord
        include Easyhooks
      end
    end
    assert_equal 'Easyhooks can only be included in classes that extend from ActiveRecord::Base', error.message
  end
end