class Band < ApplicationRecord
  self.per_page = 30
	validates :bn_url, presence: true, uniqueness: true, on: :create
	validates :bn_head, presence: true, uniqueness: true, on: :create
end
