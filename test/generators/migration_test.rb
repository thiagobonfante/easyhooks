require_relative './rails_helper'
require_relative File.expand_path("../../../lib/generators/easyhooks/migration/migration_generator", __FILE__)

class MigrationTest < ::Rails::Generators::TestCase
  tests Easyhooks::MigrationGenerator
  destination File.expand_path("./tmp", File.dirname(__FILE__))

  def setup
    run_generator
  end

  def teardown
    FileUtils.rm_rf(destination_root)
  end

  test "should generate migration for easyhooks" do
    file_name = "easyhooks_migration.rb"
    db_path = "db/migrate/#{Time.current.strftime('%Y%m%d%H%M%S')}_#{file_name}"
    path = File.expand_path("../tmp/#{db_path}", __FILE__)
    assert_file path do |content|
      assert_match(/create_table :easyhooks_store/, content)
    end
  end

  private

  def create_generator_sample_app
    path = File.join(File.dirname(__FILE__), "..")
    FileUtils.cd(path) do
      system "rails new tmp --skip-active-record --skip-test-unit --skip-spring --skip-bundle --quiet"
    end
  end
end