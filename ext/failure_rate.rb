require 'sinatra/extension'

module FailureRate
  extend Sinatra::Extension

  before do
    if ENV.key?("FAILURE_RATE") && Random.rand(1.0) <= ENV["FAILURE_RATE"].to_f && request.head?
      halt 503
    end
  end
end

register FailureRate
