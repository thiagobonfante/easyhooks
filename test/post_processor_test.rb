require './test/test_helper'

class PostProcessorTest < ActiveRecordTestCase

  test 'e2e testing' do
    assert_enqueued_jobs 0

    o = Order.first
    # o.destroy!
    o.update!(description: 'some order')
    # Easyhooks::PostProcessor.perform_later(Order.name, {name: 'some order', id: 1, description: 'some description'}.to_json, :my_default_trigger, :create)
    # assert_enqueued_jobs 1, only: Easyhooks::PostProcessor

    o2 = Order.create!(name: 'some order 2', description: 'some description 2')

    # make Net::HTTP request raise an error
    # Net::HTTP.any_instance.stubs(:request).raises(StandardError.new('some error'))
    #
    perform_enqueued_jobs
  end

  test 'should send a post request to the configured url as default trigger' do
    assert_enqueued_jobs 0

    Easyhooks::PostProcessor.perform_later(Order.name, {name: 'some order', id: 1, description: 'some description'}.to_json, :my_default_trigger)
    assert_enqueued_jobs 1, only: Easyhooks::PostProcessor

    expected_endpoint = 'https://easyhooks.io/my_default_trigger'
    expected_parsed_uri = URI.parse(expected_endpoint)
    URI.expects(:parse).with(expected_endpoint).returns(expected_parsed_uri)
    Net::HTTP.expects(:new).with(expected_parsed_uri.host, expected_parsed_uri.port).returns(mock_http = mock())
    mock_http.expects(:use_ssl=).with(true)
    Net::HTTP::Post.expects(:new).with(expected_parsed_uri.request_uri).returns(mock_request = mock())
    mock_request.expects(:body=).with({name: 'some order', id: 1, description: 'some description'}.to_json)
    mock_request.expects(:[]=).with('Content-Type', 'application/json')
    mock_http.expects(:request).with(mock_request).returns(mock_response = mock())
    mock_response.expects(:body).returns('some response body')

    perform_enqueued_jobs
  end

  test 'should send a post request to the configured url as yaml trigger' do
    assert_enqueued_jobs 0

    vendor_json = {name: 'some vendor', id: 1, description: 'some description'}.to_json
    Easyhooks::PostProcessor.perform_later(Vendor.name, vendor_json, :my_yaml_trigger)
    assert_enqueued_jobs 1, only: Easyhooks::PostProcessor

    expected_endpoint = 'https://easyhooks.io/my_yaml_trigger'
    expected_parsed_uri = URI.parse(expected_endpoint)
    URI.expects(:parse).with(expected_endpoint).returns(expected_parsed_uri)
    Net::HTTP.expects(:new).with(expected_parsed_uri.host, expected_parsed_uri.port).returns(mock_http = mock())
    mock_http.expects(:use_ssl=).with(true)
    Net::HTTP::Post.expects(:new).with(expected_parsed_uri.request_uri).returns(mock_request = mock())
    mock_request.expects(:body=).with(vendor_json)
    mock_request.expects(:[]=).with('Content-Type', 'application/json')
    mock_http.expects(:request).with(mock_request).returns(mock_response = mock())
    mock_response.expects(:body).returns('some response body')

    perform_enqueued_jobs
  end

  test 'should send a post request to the configured url as db trigger' do
    assert_enqueued_jobs 0

    vendor_json = {name: 'some vendor', id: 1, description: 'some description'}.to_json
    Easyhooks::PostProcessor.perform_later(Vendor.name, vendor_json, :my_db_trigger)
    assert_enqueued_jobs 1, only: Easyhooks::PostProcessor

    expected_endpoint = 'https://easyhooks.io/my_db_trigger'
    expected_parsed_uri = URI.parse(expected_endpoint)
    URI.expects(:parse).with(expected_endpoint).returns(expected_parsed_uri)
    Net::HTTP.expects(:new).with(expected_parsed_uri.host, expected_parsed_uri.port).returns(mock_http = mock())
    mock_http.expects(:use_ssl=).with(true)
    Net::HTTP::Post.expects(:new).with(expected_parsed_uri.request_uri).returns(mock_request = mock())
    mock_request.expects(:body=).with(vendor_json)
    mock_request.expects(:[]=).with('Content-Type', 'application/json')
    mock_http.expects(:request).with(mock_request).returns(mock_response = mock())
    mock_response.expects(:body).returns('some response body')

    perform_enqueued_jobs
  end
end
