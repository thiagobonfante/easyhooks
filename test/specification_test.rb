# frozen_string_literal: true

require './test/test_helper'

class SpecificationTest < Minitest::Test

  test 'should create spec' do
    specification = Proc.new do
      trigger :submit do
        action :users, method: :post, endpoint: 'http://localhost:3000/users'
      end
    end
    spec = Easyhooks::Specification.new(
      'Vendor',
      :default,
      &specification
    )
    assert_equal 1, spec.actions.count
    assert_equal 1, spec.triggers.count
  end

  test 'should validate spec on attribute' do
    specification = Proc.new do
      trigger :submit do
        action :users, method: :post, endpoint: 'http://localhost:3000/users'
      end
    end
    error = assert_raises(TypeError) do
      Easyhooks::Specification.new(
        'Vendor',
         :default,
        { on: :created },
        &specification
      )
    end
    assert_equal "Invalid attribute 'on' for Easyhooks::Trigger submit: [:created]. Allowed values are: [:create, :update, :destroy]", error.message
  end

  test 'should operate spec with only attribute' do
    specification = Proc.new do
      trigger :submit do
        action :users, method: :post, endpoint: 'http://localhost:3000/users'
      end
    end

    spec = Easyhooks::Specification.new(
      'Vendor',
      :stored,
      { only: :name },
      &specification
    )
    assert_equal 1, spec.triggers.count
    assert_equal [:name], spec.triggers[:submit].only
  end

  test 'should validate spec if attribute' do
    specification = Proc.new do
      trigger :submit do
        action :users, method: :post, endpoint: 'http://localhost:3000/users'
      end
    end
    error = assert_raises(TypeError) do
      Easyhooks::Specification.new(
        'Vendor',
        :stored,
        { if: 'condition' },
        &specification
      )
    end
    assert_equal "Invalid attribute 'if' for Easyhooks::Trigger submit: if must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate spec payload attribute' do
    specification = Proc.new do
      trigger :submit do
        action :users, method: :post, endpoint: 'http://localhost:3000/users'
      end
    end
    error = assert_raises(TypeError) do
      Easyhooks::Specification.new(
        'Vendor',
        :stored,
        { payload: 'payload' },
        &specification
      )
    end
    assert_equal "Invalid attribute 'payload' for Easyhooks::Trigger submit: payload must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end

  test 'should validate spec on_fail attribute' do
    specification = Proc.new do
      trigger :submit do
        action :users, method: :post, endpoint: 'http://localhost:3000/users'
      end
    end
    error = assert_raises(TypeError) do
      Easyhooks::Specification.new(
        'Vendor',
        :stored,
        { on_fail: 'on_fail' },
        &specification
      )
    end
    assert_equal "Invalid attribute 'on_fail' for Easyhooks::Trigger submit: on_fail must be nil, an instance method name symbol or a callable (eg. a proc or lambda)", error.message
  end
end