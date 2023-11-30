# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../../config/environment.rb", __FILE__)

require "rails/test_help"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "minitest/autorun"