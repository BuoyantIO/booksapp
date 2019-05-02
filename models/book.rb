require 'sinatra/activerecord'
require_relative '../resources/author'

class Book < ActiveRecord::Base
  validates_presence_of :title, :pages
  validates_numericality_of :pages, :greater_than => 0
  validate :author_exists

  private

  def author_exists
    errors.add(:author_id, "does not exist") unless Author.exists?(author_id)
  end
end
