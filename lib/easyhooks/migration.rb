# frozen_string_literal: true

require_relative '../generators/easyhooks/migration/templates/migration'

module Easyhooks
  class Migration

    def self.up
      EasyhooksMigration.migrate(:up)
    end
  end
end
