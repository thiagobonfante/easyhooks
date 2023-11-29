# frozen_string_literal: true

require './test/test_helper'

class ActionTest < ActiveRecordTestCase

  def setup
    super
    @hook = Easyhooks::Hook.new
    @hook.endpoint = 'http://localhost:3000/users'
    @hook.method = :post
    @hook.auth = 'Basic YWxhZGRpbjpvcGVuc2VzYW1l'
    @hook.headers = { 'x-test' => 'test' }
  end

  test 'should create action' do
    action = Easyhooks::Action.new(
      'users',
      'create',
      @hook
    )
    assert_equal 'users', action.name
  end

  test 'should validate action name' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'users$',
        'create',
        @hook
      )
    end
    assert_equal 'Invalid Easyhooks::Action name \'users$\'. Name can only have alphanumeric characters and underscore', error.message
  end

  test 'should validate action name as nil' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        nil,
        'create',
        @hook
      )
    end
    assert_equal "Easyhooks::Action name can't be nil", error.message
  end

  test 'should validate action type' do
    # assert raises TypeError with message
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'users',
        'create',
        @hook,
        {
          type: :none
        }
      )
    end
    assert_equal 'Invalid Easyhooks::Action type: none', error.message
  end

  test 'should return action type default if nil' do
    action = Easyhooks::Action.new(
      'users',
      'create',
      @hook
    )
    assert_equal :default, action.type
  end

  test 'should validate action method' do
    # assert raises TypeError with message
    @hook.method = :posted
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'users',
        'create',
        @hook
      )
    end
    assert_equal "Invalid method 'posted' for Easyhooks::Action 'users'. Allowed values are: [:get, :post, :put, :patch, :delete]", error.message
  end

  test 'should return method post for if method is nil and type not stored' do
    @hook.method = nil
    action = Easyhooks::Action.new(
      'users',
      'create',
      @hook
    )
    assert_equal :post, action.hook.method
  end

  test 'should return method nil for if method is nil and type stored' do
    @hook.method = nil
    action = Easyhooks::Action.new(
      'users',
      'create',
      @hook,
      {
        type: :stored
      }
    )
    assert_nil action.hook.method
  end

  test 'should validate action endpoint' do
    @hook.endpoint = 'httxptt://ˆˆlocalhost:3000/users'
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'users',
        'create',
        @hook
      )
    end
    assert_equal "Easyhooks::Action endpoint is not a valid URL: httxptt://ˆˆlocalhost:3000/users", error.message
  end

  test 'should validate action endpoint as nil' do
    @hook.endpoint = nil
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'users',
        'create',
        @hook
      )
    end
    assert_equal "Easyhooks::Action endpoint can't be nil", error.message
  end

  test 'should return nil endpoint for action if type stored' do
    @hook.endpoint = nil
    action = Easyhooks::Action.new(
      'users',
      'create',
      @hook,
      {
        type: :stored
      }
    )
    assert_nil action.hook.endpoint
  end

  test 'should validate action condition' do
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'users',
        'create',
        @hook,
        {
          if: 'condition'
        }
      )
    end
    assert_equal "Invalid attribute 'if' for Easyhooks::Action users: if must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate action payload' do
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'users',
        'create',
        @hook,
        {
          payload: 'payload'
        }
      )
    end
    assert_equal "Invalid attribute 'payload' for Easyhooks::Action users: payload must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate action on_fail' do
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'users',
        'create',
        @hook,
        {
          on_fail: 'on_fail'
        }
      )
    end
    assert_equal "Invalid attribute 'on_fail' for Easyhooks::Action users: on_fail must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should do nothing when action load! is called for default type' do
    action = Easyhooks::Action.new(
      'users',
      'create',
      @hook
    )
    assert_nil action.load!
    assert_equal :default, action.type
    assert_equal :post, action.hook.method
    assert_equal 'http://localhost:3000/users', action.hook.endpoint
  end

  test 'should load action from database with context actions when load! is called for stored type' do
    action = Easyhooks::Action.new(
      'users',
      'create',
      @hook,
      {
        type: :stored
      }
    )
    stored_action = Easyhooks::Store.new(method: :get, endpoint: 'http://localhost:3000/users', name: 'users', context: 'actions')
    Easyhooks::Store.expects(:find_by).with(name: 'users', context: 'actions').returns(stored_action)
    action.load!
    assert_equal :stored, action.type
    assert_equal :get, action.hook.method
    assert_equal 'http://localhost:3000/users', action.hook.endpoint
  end

  test 'should load action from database with context triggers when load! is called for stored type' do
    action = Easyhooks::Action.new(
      'users',
      'create',
      @hook,
      {
        type: :stored
      }
    )
    stored_trigger = Easyhooks::Store.new(method: :get, endpoint: 'http://localhost:3000/users', name: 'create', context: 'triggers')
    Easyhooks::Store.expects(:find_by).with(name: 'users', context: 'actions').returns(nil)
    Easyhooks::Store.expects(:find_by).with(name: 'create', context: 'triggers').returns(stored_trigger)
    action.load!
    assert_equal :stored, action.type
    assert_equal :get, action.hook.method
    assert_equal 'http://localhost:3000/users', action.hook.endpoint
  end

  test 'should load action from database with context class when load! is called for stored type' do
    action = Easyhooks::Action.new(
      'users',
      'create',
      @hook,
      {
        type: :stored
      }
    )
    stored_action = Easyhooks::Store.new(method: :get, endpoint: 'http://localhost:3000/users', name: 'Vendor', context: 'classes')
    Easyhooks::Store.expects(:find_by).with(name: 'users', context: 'actions').returns(nil)
    Easyhooks::Store.expects(:find_by).with(name: 'create', context: 'triggers').returns(nil)
    Easyhooks::Store.expects(:find_by).with(name: 'Vendor', context: 'classes').returns(stored_action)
    action.load!('Vendor')
    assert_equal :stored, action.type
    assert_equal :get, action.hook.method
    assert_equal 'http://localhost:3000/users', action.hook.endpoint
  end
end