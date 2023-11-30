# frozen_string_literal: true

require_relative './store_values'

module Easyhooks
  class Store < ActiveRecord::Base
    self.table_name = 'easyhooks_store'

    has_many :values, class_name: 'Easyhooks::StoreValues', dependent: :destroy

    validates_presence_of :name, :method, :endpoint, :context

    def add_headers(headers)
      headers.each do |key, value|
        values.create(context: 'headers', key: key, value: value)
      end
    end

    def add_auth(type, auth)
      values.create(context: 'auth', key: type, value: auth)
    end

    def headers
      values.where(context: 'headers').map { |v| [v.key, v.value] }.to_h
    end

    def auth
      auth = values.where(context: 'auth').first
      return nil unless auth.present?

      "#{auth.key} #{auth.value}"
    end
  end
end

# == Schema Information
#
# Table name: easyhooks_store
#
#  id             :integer          not null, primary key
#  context        :string           not null
#  name           :string           not null
#  method         :string           not null
#  endpoint       :string           not null
#  created_at     :datetime
#  updated_at     :datetime
#
# Indexes
#
#  index_easyhooks_store_on_name_and_context (name, context) UNIQUE
#