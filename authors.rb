require 'sinatra'
require 'sinatra/json'

require_relative 'ext/failure_rate'
require_relative 'models/author'
require_relative 'resources/book'

get '/authors.json' do
  authors = Author.where(params.slice(*Author.attribute_names)).order(params[:order])
  json authors
end

get '/authors/:id.json' do
  if author = Author.find_by_id(params[:id])
    json author
  else
    404
  end
end

post '/authors.json' do
  author = Author.new(JSON.parse(request.body.read))
  if author.save
    [201, {'Location' => "/authors/#{author.id}.json"}, author.to_json]
  else
    [422, author.errors.to_json]
  end
end

put '/authors/:id.json' do
  if author = Author.find_by_id(params[:id])
    if author.update(JSON.parse(request.body.read).slice(*%w{first_name last_name}))
      [200, {'Location' => "/authors/#{author.id}.json"}, author.to_json]
    else
      [422, author.errors.to_json]
    end
  else
    404
  end
end

delete '/authors/:id.json' do
  if author = Author.find_by_id(params[:id])
    author.destroy
    204
  else
    404
  end
end

get '/ping' do
  [200, {"Content-Type" => "text/plain"}, "pong"]
end
