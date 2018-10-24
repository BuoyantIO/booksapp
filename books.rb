require 'sinatra'
require 'sinatra/json'

require_relative 'ext/failure_rate'
require_relative 'models/book'
require_relative 'resources/author'

get '/books.json' do
  books = Book.where(params.slice(*Book.attribute_names)).order(params[:order])
  json books
end

get '/books/:id.json' do
  if book = Book.find_by_id(params[:id])
    json book
  else
    404
  end
end

post '/books.json' do
  book = Book.new(JSON.parse(request.body.read))
  if book.save
    [201, {'Location' => "/books/#{book.id}.json"}, book.to_json]
  else
    [422, book.errors.to_json]
  end
end

put '/books/:id.json' do
  if book = Book.find_by_id(params[:id])
    if book.update(JSON.parse(request.body.read).slice(*%w{title author_id pages}))
      [200, {'Location' => "/books/#{book.id}.json"}, book.to_json]
    else
      [422, book.errors.to_json]
    end
  else
    404
  end
end

delete '/books/:id.json' do
  if book = Book.find_by_id(params[:id])
    book.destroy
    204
  else
    404
  end
end

get '/ping' do
  [200, {"Content-Type" => "text/plain"}, "pong"]
end
