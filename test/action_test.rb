# frozen_string_literal: true

require './test/test_helper'

class ActionTest < Minitest::Test

  test 'should create action and set default values' do
    action = Easyhooks::Action.new(
      'submit',
      nil,
      nil,
      nil,
      nil,
      nil
    )
    assert_equal 'submit', action.name
    assert_equal [:create, :update, :destroy], action.on
    assert_equal [], action.only
  end

  test 'should validate action name' do
    error = assert_raises(TypeError) do
      action = Easyhooks::Action.new(
        'submit$',
        nil,
        nil,
        nil,
        nil,
        nil
      )
    end
    assert_equal 'Invalid Easyhooks::Action name \'submit$\'. Name can only have alphanumeric characters and underscore', error.message
  end

  test 'should validate action name as nil' do
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        nil,
        nil,
        nil,
        nil,
        nil,
        nil
      )
    end
    assert_equal "Easyhooks::Action name can't be nil", error.message
  end

  test 'should validate action on' do
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'submit',
        'created',
        nil,
        nil,
        nil,
        nil
      )
    end
    assert_equal 'Invalid attribute \'on\' for Easyhooks::Action submit: [:created]. Allowed values are: [:create, :update, :destroy]', error.message
  end

  test 'should return action only default blank array if nil' do
    action =  Easyhooks::Action.new(
      'submit',
      'create',
      nil,
      nil,
      nil,
      nil
    )
    assert_equal [], action.only
  end

  test 'should validate action condition' do
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'submit',
        'create',
        :name,
        'condition',
        nil,
        nil
      )
    end
    assert_equal "Invalid attribute 'if' for Easyhooks::Action submit: if must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate action payload' do
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'submit',
        'create',
        :name,
        nil,
        'payload',
        nil
      )
    end
    assert_equal "Invalid attribute 'payload' for Easyhooks::Action submit: payload must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate action on_fail' do
    error = assert_raises(TypeError) do
      Easyhooks::Action.new(
        'submit',
        'create',
        :name,
        nil,
        nil,
        'on_fail'
      )
    end
    assert_equal "Invalid attribute 'on_fail' for Easyhooks::Action submit: on_fail must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should add trigger to action' do
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
    action = Easyhooks::Action.new(
      'submit',
      nil,
      nil,
      nil,
      nil,
      nil
    )
    action.add_trigger(trigger)
    assert_equal 1, action.triggers.length
    assert_equal trigger, action.triggers.first
  end
end