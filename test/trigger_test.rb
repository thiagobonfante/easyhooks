# frozen_string_literal: true

require './test/test_helper'

class TriggerTest < Minitest::Test

  test 'should create trigger and set default values' do
    trigger = Easyhooks::Trigger.new(
      'submit',
      nil,
      {}
    )
    assert_equal 'submit', trigger.name
    assert_equal [:create, :update, :destroy], trigger.on
    assert_equal [], trigger.only
  end

  test 'should validate trigger name' do
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'submit$',
        nil,
        {}
      )
    end
    assert_equal 'Invalid Easyhooks::Trigger name \'submit$\'. Name can only have alphanumeric characters and underscore', error.message
  end

  test 'should validate trigger name as nil' do
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        nil,
        nil,
        {}
      )
    end
    assert_equal "Easyhooks::Trigger name can't be nil", error.message
  end

  test 'should validate trigger on' do
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'submit',
        nil,
        {
          on: :created
        }
      )
    end
    assert_equal "Invalid attribute 'on' for Easyhooks::Trigger submit: [:created]. Allowed values are: [:create, :update, :destroy]", error.message
  end

  test 'should return trigger only default blank array if nil' do
    trigger = Easyhooks::Trigger.new(
      'submit',
      nil,
      {}
    )
    assert_equal [], trigger.only
  end

  test 'should validate trigger condition' do
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'submit',
        nil,
        {
          if: 'if'
        }
      )
    end
    assert_equal "Invalid attribute 'if' for Easyhooks::Trigger submit: if must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate trigger payload' do
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'submit',
        nil,
        {
          payload: 'payload'
        }
      )
    end
    assert_equal "Invalid attribute 'payload' for Easyhooks::Trigger submit: payload must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate trigger on_fail' do
    error = assert_raises(TypeError) do
      Easyhooks::Trigger.new(
        'submit',
        nil,
        {
          on_fail: 'on_fail'
        }
      )
    end
    assert_equal "Invalid attribute 'on_fail' for Easyhooks::Trigger submit: on_fail must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should add action to trigger' do
    hook = Easyhooks::Hook.new
    hook.endpoint = 'http://localhost:3000/users'
    hook.method = :post
    hook.auth = 'Basic YWxhZGRpbjpvcGVuc2VzYW1l'
    hook.headers = { 'x-test' => 'test' }
    action = Easyhooks::Action.new(
      'users',
      'submit',
      hook
    )
    trigger = Easyhooks::Trigger.new(
      'submit',
      nil,
      {}
    )
    trigger.add_action(action)
    assert_equal 1, trigger.actions.length
    assert_equal action, trigger.actions.first
  end
end