require 'active_resource'
require 'active_resource/persistent'

BOOKS_SITE = ENV["BOOKS_SITE"] || "http://localhost:7002"

class Book < ActiveResource::Base
  self.site = BOOKS_SITE
end
