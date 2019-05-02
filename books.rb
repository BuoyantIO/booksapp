this_dir = File.expand_path(File.dirname(__FILE__))
pb_dir = File.join(this_dir, 'pb')
$LOAD_PATH.unshift(pb_dir) unless $LOAD_PATH.include?(pb_dir)

require 'grpc'
require 'books_services_pb'
require_relative 'models/book'

class BooksServer < Proto::Books::Service
  def get_books(req, _unused_call)
    where = req.author_id == 0 ? {} : {author_id: req.author_id}
    books = Book.where(where).order(req.order)
    Proto::GetBooksResponse.new(books: books.map {|b| db_to_pb(b)})
  end

  def get_book(req, _unused_call)
    book = Book.find_by_id(req.book_id)
    Proto::GetBookResponse.new(book: db_to_pb(book))
  end

  def create_book(req, _unused_call)
    book = Book.new(title: req.title, pages: req.pages, author_id: req.author_id)
    book.save
    Proto::CreateBookResponse.new(book: db_to_pb(book))
  end

  def update_book(req, _unused_call)
    if book = Book.find_by_id(req.book.id)
      book.update_attributes(title: req.book.title, pages: req.book.pages, author_id: req.book.author_id)
    end
    Proto::UpdateBookResponse.new
  end

  def delete_book(req, _unused_call)
    if book = Book.find_by_id(req.book_id)
      book.destroy
    end
    Proto::DeleteBookResponse.new
  end

  private

  def db_to_pb(book)
    attrs = book.attributes.slice("id", "title", "pages", "author_id")
    Proto::Book.new(attrs)
  end
end

def main
  s = GRPC::RpcServer.new
  s.add_http2_port('0.0.0.0:7002', :this_port_is_insecure)
  s.handle(BooksServer)
  s.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT'])
end

main
