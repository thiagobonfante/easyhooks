require './test/test_helper'

class MainTest < ActiveRecordTestCase

  test 'should dispatch only order action my_default_action' do
    o = Order.all.first
    assert 'some order', o.name

    expected_payload = order_payload(o.id,'name has changed', o.description, Order.count).to_json
    Easyhooks::PostProcessor.expects(:perform_later).with('Order', 1, expected_payload, :my_default_action, :update)

    o.name = 'name has changed'
    o.save!
  end

  test 'should dispatch both order actions' do

    expected_payload = order_payload(2, 'some other order', 'some other description', 2).to_json
    Easyhooks::PostProcessor.expects(:perform_later).with('Order', 2, expected_payload, :my_default_action, :create)
    Easyhooks::PostProcessor.expects(:perform_later).with('Order', 2, expected_payload, :my_other_action, :create)

    Order.create!(name: 'some other order', description: 'some other description')
  end

  test 'should only dispatch vendor actions only if name has changed' do

    v = Vendor.first
    v.description = 'changed description'
    v.save!
    Easyhooks::PostProcessor.expects(:perform_later).never
  end

  test 'should dispatch vendor actions because name has changed' do

    Easyhooks::PostProcessor.expects(:perform_later).with('Vendor', 1, { id: 1 }.to_json, :my_yaml_action, :update).once
    Easyhooks::PostProcessor.expects(:perform_later).with('Vendor', 1, { id: 1 }.to_json, :my_db_action, :update).once
    v = Vendor.first
    v.name = 'vendor name changed'
    v.save!
  end

  test 'should dispatch user actions because is was destroyed' do

    Easyhooks::PostProcessor.expects(:perform_later).with('User', 1, { id: 1 }.to_json, :my_db_action, :destroy).once
    u = User.first
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

  private

  def order_payload(id, name, description, count)
    {
      id: id,
      name: name,
      description: description,
      metadata: {
        count: count
      }
    }
  end
end