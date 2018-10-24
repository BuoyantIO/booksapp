require 'active_resource'
require 'active_resource/persistent'

AUTHORS_SITE = ENV["AUTHORS_SITE"] || "http://localhost:7001"

class Author < ActiveResource::Base
  self.site = AUTHORS_SITE

  def name; "#{first_name} #{last_name}"; end
end
