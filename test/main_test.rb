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
    Easyhooks::PostProcessor.expects(:perform_later).with('Order', expected_order.to_json, :my_default_trigger, :update)

    o.name = 'name has changed'
    o.save!

    v = Vendor.all.first
    assert 'some vendor', v.name
    expected_vendor = {
      "name": 'name has changed',
      "id": v.id,
      "description": 'some description'
    }
    Easyhooks::PostProcessor.expects(:perform_later).with('Vendor', expected_vendor.to_json, :my_yaml_trigger, :update)
    Easyhooks::PostProcessor.expects(:perform_later).with('Vendor', expected_vendor.to_json, :my_db_trigger, :update)

    v.name = 'name has changed'
    v.save!

    u = User.all.first
    u.name = 'some name changed'
    u.save!

    expected_user = {
      "name": 'some name changed',
      "id": u.id,
      "email": 'some@email.com'
    }
    Easyhooks::PostProcessor.expects(:perform_later).with('User', expected_user.to_json, :my_db_trigger, :destroy)
    u.destroy!
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