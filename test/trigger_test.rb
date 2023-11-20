# frozen_string_literal: true

require './test/test_helper'

class TriggerTest < ActiveRecordTestCase

  test 'should create trigger' do
    trigger = Easyhooks::Trigger.new(
      'users',
      'create',
      :default,
      :post,
      'http://localhost:3000/users',
      nil,
      nil,
      nil
    )
    assert_equal 'users', trigger.name
  end

  test 'should validate trigger name' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'users$',
        'create',
        :default,
        :post,
        'http://localhost:3000/users',
        nil,
        nil,
        nil
      )
    end
    assert_equal 'Invalid Easyhooks::Trigger name \'users$\'. Name can only have alphanumeric characters and underscore', error.message
  end

  test 'should validate trigger name as nil' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        nil,
        'create',
        :default,
        :post,
        'http://localhost:3000/users',
        nil,
        nil,
        nil
      )
    end
    assert_equal "Easyhooks::Trigger name can't be nil", error.message
  end

  test 'should validate trigger type' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'users',
        'create',
        :none,
        :post,
        'http://localhost:3000/users',
        nil,
        nil,
        nil
      )
    end
    assert_equal 'Invalid Easyhooks::Trigger type: none', error.message
  end

  test 'should return trigger type default if nil' do
    trigger =  Easyhooks::Trigger.new(
      'users',
      'create',
      nil,
      :post,
      'http://localhost:3000/users',
      nil,
      nil,
      nil
    )
    assert_equal :default, trigger.type
  end

  test 'should validate trigger method' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'users',
        'create',
        :default,
        :posted,
        'http://localhost:3000/users',
        nil,
        nil,
        nil
      )
    end
    assert_equal "Invalid method 'posted' for Easyhooks::Trigger 'users'. Allowed values are: [:get, :post, :put, :patch, :delete]", error.message
  end

  test 'should return method post for if method is nil and type not stored' do
    trigger = Easyhooks::Trigger.new(
      'users',
      'create',
      :default,
      nil,
      'http://localhost:3000/users',
      nil,
      nil,
      nil
    )
    assert_equal :post, trigger.method
  end

  test 'should return method nil for if method is nil and type stored' do
    trigger = Easyhooks::Trigger.new(
      'users',
      'create',
      :stored,
      nil,
      'http://localhost:3000/users',
      nil,
      nil,
      nil
    )
    assert_nil trigger.method
  end

  test 'should validate trigger endpoint' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'users',
        'create',
        :default,
        :post,
        'httxptt://ˆˆlocalhost:3000/users',
        nil,
        nil,
        nil
      )
    end
    assert_equal "Easyhooks::Trigger endpoint is not a valid URL: httxptt://ˆˆlocalhost:3000/users", error.message
  end

  test 'should validate trigger endpoint as nil' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'users',
        'create',
        :default,
        :post,
        nil,
        nil,
        nil,
        nil
      )
    end
    assert_equal "Easyhooks::Trigger endpoint can't be nil", error.message
  end

  test 'should return nil endpoint for trigger if type stored' do
    trigger =  Easyhooks::Trigger.new(
      'users',
      'create',
      :stored,
      :post,
      nil,
      nil,
      nil,
      nil
    )
    assert_nil trigger.endpoint
  end

  test 'should validate trigger condition' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'users',
        'create',
        :default,
        :post,
        'http://localhost:3000/users',
        'condition',
        nil,
        nil
      )
    end
    assert_equal "Invalid attribute 'if' for Easyhooks::Trigger users: if must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate trigger payload' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'users',
        'create',
        :default,
        :post,
        'http://localhost:3000/users',
        nil,
        'payload',
        nil
      )
    end
    assert_equal "Invalid attribute 'payload' for Easyhooks::Trigger users: payload must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate trigger on_fail' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'users',
        'create',
        :default,
        :post,
        'http://localhost:3000/users',
        nil,
        nil,
        'on_fail'
      )
    end
    assert_equal "Invalid attribute 'on_fail' for Easyhooks::Trigger users: on_fail must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should do nothing when trigger load! is called for default type' do
    trigger = Easyhooks::Trigger.new(
      'users',
      'create',
      :default,
      :post,
      'http://localhost:3000/users',
      nil,
      nil,
      nil
    )
    assert_nil trigger.load!
    assert_equal :default, trigger.type
    assert_equal :post, trigger.method
    assert_equal 'http://localhost:3000/users', trigger.endpoint
  end

  test 'should load trigger from database when load! is called for stored type' do
    trigger = Easyhooks::Trigger.new(
      'users',
      'create',
      :stored,
      nil,
      nil,
      nil,
      nil,
      nil
    )
    stored_trigger = Easyhooks::StoredTrigger.new(method: :get, endpoint: 'http://localhost:3000/users', name: 'users')
    Easyhooks::StoredTrigger.expects(:find_by).with(name: 'users').returns(stored_trigger)
    trigger.load!
    assert_equal :stored, trigger.type
    assert_equal :get, trigger.method
    assert_equal 'http://localhost:3000/users', trigger.endpoint
  end
end