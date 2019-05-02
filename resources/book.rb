this_dir = File.expand_path(File.dirname(__FILE__))
pb_dir = File.join(this_dir, '../pb')
$LOAD_PATH.unshift(pb_dir) unless $LOAD_PATH.include?(pb_dir)

require 'grpc'
require 'books_services_pb'

BOOKS_ADDR = ENV["BOOKS_ADDR"] || "localhost:7002"

class Proto::Book
  def valid?
    true
  end

  def destroy
    Book.delete(id)
  end

  def update_attributes(params)
    Book.update_attributes(params.merge("id": id))
  end
end

class Book
  class << self
    @@client = Proto::Books::Stub.new(BOOKS_ADDR, :this_channel_is_insecure)

    def all(options)
      req = Proto::GetBooksRequest.new(options[:params])
      @@client.get_books(req).books
    end

    def find(id)
      req = Proto::GetBookRequest.new(book_id: id.to_i)
      @@client.get_book(req).book
    end

    def create(params)
      params["pages"] = params["pages"].to_i
      params["author_id"] = params["author_id"].to_i
      req = Proto::CreateBookRequest.new(params)
      @@client.create_book(req).book
    end

    def update_attributes(params)
      params["pages"] = params["pages"].to_i
      params["author_id"] = params["author_id"].to_i
      book = Proto::Book.new(params)
      req = Proto::UpdateBookRequest.new(book: book)
      @@client.update_book(req)
    end

    def delete(id)
      req = Proto::DeleteBookRequest.new(book_id: id.to_i)
      @@client.delete_book(req)
    end
  end
end
