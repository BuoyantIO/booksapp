require 'sinatra'
require 'sinatra/base'
require 'rack-flash'

enable :sessions
set    :session_secret, 'a book is a dream that you hold in your hand'
use Rack::Flash

require_relative 'ext/failure_rate'
require_relative 'resources/author'
require_relative 'resources/book'

# index
get '/' do
  @books = Book.all(:params => {:order => "lower(title)"})
  @books_by_author = @books.group_by(&:author_id)

  @authors = Author.all(:params => {:order => "lower(last_name)"})
  @authors_by_id = @authors.index_by(&:id)

  erb :index
end

# show author
get '/authors/:id' do
  rescue_not_found do
    @author = Author.find(params[:id])
    @authors_by_id = [@author].index_by(&:id)
    @books = Book.all(:params => {:author_id => @author.id, :order => "lower(title)"})
    erb :author
  end
end

# create author
post '/authors' do
  author = Author.create(params)
  if author.valid?
    flash[:notice] = "Author \"#{author.name}\" created"
    redirect to("/authors/#{author.id}")
  else
    flash[:error] = "Author create failed: #{author.errors.full_messages.join("; ")}"
    redirect to("/")
  end
end

# edit author form
get '/authors/:id/edit' do
  rescue_not_found do
    @author = Author.find(params[:id])
    erb :edit_author
  end
end

# edit author
post '/authors/:id/edit' do
  rescue_not_found do
    author = Author.find(params[:id])
    if author.update_attributes(params.slice(*%w{first_name last_name}))
      flash[:notice] = "Author \"#{author.name}\" updated"
    else
      flash[:error] = "Author update failed: #{author.errors.full_messages.join("; ")}"
    end
    redirect to("/authors/#{author.id}")
  end
end

# delete author
post '/authors/:id/delete' do
  rescue_not_found do
    if Author.delete(params[:id])
      flash[:notice] = "Author deleted"
    else
      flash[:error] = "Failed to delete author"
    end
    redirect to("/")
  end
end

# show book
get '/books/:id' do
  rescue_not_found do
    @book = Book.find(params[:id])
    @author = Author.find(@book.author_id)
    erb :book
  end
end

# create book
post '/books' do
  book = Book.create(params)
  if book.valid?
    flash[:notice] = "Book \"#{book.title}\" created"
    redirect to("/books/#{book.id}")
  else
    flash[:error] = "Book create failed: #{book.errors.full_messages.join("; ")}"
    redirect to("/")
  end
end

# edit book form
get '/books/:id/edit' do
  rescue_not_found do
    @book = Book.find(params[:id])
    @authors = Author.all(:params => {:order => "lower(last_name)"})
    erb :edit_book
  end
end

# edit book
post '/books/:id/edit' do
  rescue_not_found do
    book = Book.find(params[:id])
    if book.update_attributes(params.slice(*%w{title author_id pages}))
      flash[:notice] = "Book \"#{book.title}\" updated"
    else
      flash[:error] = "Book update failed: #{book.errors.full_messages.join("; ")}"
    end
    redirect to("/books/#{book.id}")
  end
end

# delete book
post '/books/:id/delete' do
  rescue_not_found do
    if Book.delete(params[:id])
      flash[:notice] = "Book deleted"
    else
      flash[:error] = "Failed to delete book"
    end
    redirect to("/")
  end
end

get '/reset' do
  Author.find(:all, :params => {:last_name => "Cline"}).each do |author|
    author.destroy
  end
  204
end

get '/ping' do
  [200, {"Content-Type" => "text/plain"}, "pong"]
end

private

def rescue_not_found(&block)
  yield
rescue ActiveResource::ResourceNotFound
  flash[:error] = "Not found"
  redirect to("/")
end
