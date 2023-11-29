# frozen_string_literal: true

require_relative './store'

module Easyhooks
  class StoreValues < ActiveRecord::Base
    self.table_name = 'easyhooks_store_values'

    belongs_to :store, class_name: 'Easyhooks::Store'

    validates_presence_of :key, :value, :context
  end
end

# == Schema Information
#
# Table name: easyhooks_store_values
#
#  id                       :integer          not null, primary key
#  context                  :string           not null
#  key                      :string           not null
#  value                    :string           not null
#  easyhooks_store_id       :integer          not null
#  created_at               :datetime
#  updated_at               :datetime
#
# Indexes
#
#  index_easyhooks_store_values_on_key_and_context (key, context)
#
# Foreign Keys
#
#  fk_rails_...  (easyhooks_store_id => easyhooks_store.id)
#
