require './test/test_helper'

class MainTest < ActiveRecordTestCase

  test 'check if the post processor has been called with the proper params' do
    o = Order.all.first
    assert 'some order', o.name

    expected_order = {
      "name": 'name has changed',
      "id": o.id,
      "description": 'some description'
    }
    Easyhooks::PostProcessor.expects(:perform_later).with('Order', expected_order.to_json, :my_default_trigger)

    o.name = 'name has changed'
    o.save!

    v = Vendor.all.first
    assert 'some vendor', v.name
    expected_vendor = {
      "name": 'name has changed',
      "id": v.id,
      "description": 'some description'
    }
    Easyhooks::PostProcessor.expects(:perform_later).with('Vendor', expected_vendor.to_json, :my_yaml_trigger)
    Easyhooks::PostProcessor.expects(:perform_later).with('Vendor', expected_vendor.to_json, :my_db_trigger)

    v.name = 'name has changed'
    v.save!
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