require './test/test_helper'

class PostProcessorTest < ActiveRecordTestCase

  def setup
    super
    @order = Order.first
  end

  test 'should post process Order my_default_action getting global config' do
    assert_enqueued_jobs 0

    Easyhooks::PostProcessor.perform_later(Order.name, @order.id, order_payload.to_json, :my_default_action, :update)
    assert_enqueued_jobs 1, only: Easyhooks::PostProcessor

    expected_endpoint = 'https://easyhooks.io/my_default_action'
    expected_parsed_uri = URI.parse(expected_endpoint)
    URI.expects(:parse).with(expected_endpoint).returns(expected_parsed_uri)
    Net::HTTP.expects(:new).with(expected_parsed_uri.host, expected_parsed_uri.port).returns(mock_http = mock)
    mock_http.expects(:use_ssl=).with(true)
    Net::HTTP::Post.expects(:new).with(expected_parsed_uri.request_uri).returns(mock_request = mock)
    mock_request.expects(:body=).with(override_payload(Order.name, :my_default_action, :update, order_payload).to_json)
    mock_http.expects(:verify_mode=).with(0)
    mock_request.expects(:add_field).with('Content-Type', 'application/json')
    mock_request.expects(:add_field).with('X-Easy', 'Easyhooks')
    mock_request.expects(:add_field).with('Authorization', 'Bearer token')
    mock_http.expects(:request).with(mock_request).returns(mock_response = mock)
    Easyhooks::Action.expects(:event_callable).never

    perform_enqueued_jobs
  end

  test 'should post process Order my_other_action getting global config overriding method and triggering procs' do
    assert_enqueued_jobs 0

    Easyhooks::PostProcessor.perform_later(Order.name, @order.id, { id: 1 }.to_json, :my_other_action, :update)
    assert_enqueued_jobs 1, only: Easyhooks::PostProcessor

    expected_endpoint = 'https://easyhooks.io/my_default_action'
    expected_parsed_uri = URI.parse(expected_endpoint)
    URI.expects(:parse).with(expected_endpoint).returns(expected_parsed_uri)
    Net::HTTP.expects(:new).with(expected_parsed_uri.host, expected_parsed_uri.port).returns(mock_http = mock)
    mock_http.expects(:use_ssl=).with(true)
    Net::HTTP::Put.expects(:new).with(expected_parsed_uri.request_uri).returns(mock_request = mock)
    mock_request.expects(:body=).with(default_payload('Order', :my_other_action, :update, 1).to_json)
    mock_http.expects(:verify_mode=).with(0)
    mock_request.expects(:add_field).with('Content-Type', 'application/json')
    mock_request.expects(:add_field).with('X-Easy', 'Easyhooks')
    mock_request.expects(:add_field).with('Authorization', 'Bearer token')
    mock_http.expects(:request).with(mock_request).returns(mock_response = mock)
    mock_response.expects(:code).returns('200')
    Order.any_instance.expects(:log_any).with('success').once

    perform_enqueued_jobs
  end

  test 'should post process Order my_other_action getting global config calling on_fail callback' do
    assert_enqueued_jobs 0

    Easyhooks::PostProcessor.perform_later(Order.name, @order.id, { id: 1 }.to_json, :my_other_action, :update)
    assert_enqueued_jobs 1, only: Easyhooks::PostProcessor

    expected_endpoint = 'https://easyhooks.io/my_default_action'
    expected_parsed_uri = URI.parse(expected_endpoint)
    URI.expects(:parse).with(expected_endpoint).returns(expected_parsed_uri)
    Net::HTTP.expects(:new).with(expected_parsed_uri.host, expected_parsed_uri.port).returns(mock_http = mock)
    mock_http.expects(:use_ssl=).with(true)
    Net::HTTP::Put.expects(:new).with(expected_parsed_uri.request_uri).returns(mock_request = mock)
    mock_request.expects(:body=).with(default_payload('Order', :my_other_action, :update, 1).to_json)
    mock_http.expects(:verify_mode=).with(0)
    mock_request.expects(:add_field).with('Content-Type', 'application/json')
    mock_request.expects(:add_field).with('X-Easy', 'Easyhooks')
    mock_request.expects(:add_field).with('Authorization', 'Bearer token')
    mock_http.expects(:request).with(mock_request).raises(mocked_error = StandardError.new('some error'))
    Order.any_instance.expects(:failed_action).with(mocked_error).once

    perform_enqueued_jobs
  end

  test 'should post process Order my_default_action raising an error' do
    assert_enqueued_jobs 0

    Easyhooks::PostProcessor.perform_later(Order.name, @order.id, { id: 1 }.to_json, :my_default_action, :update)
    assert_enqueued_jobs 1, only: Easyhooks::PostProcessor

    expected_endpoint = 'https://easyhooks.io/my_default_action'
    expected_parsed_uri = URI.parse(expected_endpoint)
    URI.expects(:parse).with(expected_endpoint).returns(expected_parsed_uri)
    Net::HTTP.expects(:new).with(expected_parsed_uri.host, expected_parsed_uri.port).returns(mock_http = mock)
    mock_http.expects(:use_ssl=).with(true)
    Net::HTTP::Post.expects(:new).with(expected_parsed_uri.request_uri).returns(mock_request = mock)
    mock_request.expects(:body=).with(default_payload('Order', :my_default_action, :update, 1).to_json)
    mock_http.expects(:verify_mode=).with(0)
    mock_request.expects(:add_field).with('Content-Type', 'application/json')
    mock_request.expects(:add_field).with('X-Easy', 'Easyhooks')
    mock_request.expects(:add_field).with('Authorization', 'Bearer token')
    mock_http.expects(:request).with(mock_request).raises(mocked_error = StandardError.new('some error'))

    assert_raises(StandardError) do
      perform_enqueued_jobs
    end
  end

  private

  def default_payload(object, action, event, id)
    {
      object: object,
      action: action.to_s,
      trigger: {
        name: "submitted",
        event: event.to_s.upcase
      },
      data: {
        id: id
      }
    }
  end

  def override_payload(object, action, event, data)
    payload = default_payload(object, action, event, 1)
    payload[:data] = data
    payload
  end

  def order_payload
    {
      "id": 1,
      "name": "some order",
      "description": "some order",
      "metadata": {
        "count": 1
      }
    }
  end
end
