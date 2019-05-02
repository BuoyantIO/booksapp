require 'sinatra/activerecord'
require_relative '../resources/book'

class Author < ActiveRecord::Base
  validates_presence_of :first_name, :last_name
  validates_uniqueness_of :first_name, :scope => :last_name,
    :message => "and last name are not unique"

  before_destroy :destroy_books

  private

  def destroy_books
    Book.all(:params => {:author_id => id}).each do |book|
      book.destroy
    end
  end
end
