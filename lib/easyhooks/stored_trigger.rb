# frozen_string_literal: true

module Easyhooks
  class StoredTrigger < ActiveRecord::Base
    self.table_name = 'easyhooks_stored_triggers'

    validates_presence_of :name, :method, :endpoint
  end
end

# == Schema Information
#
# Table name: easyhooks_stored_triggers
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  method         :string           not null
#  endpoint       :string           not null
#  created_at     :datetime
#  updated_at     :datetime
#
# Indexes
#
#  index_easyhooks_stored_triggers_on_name (name) UNIQUE
#