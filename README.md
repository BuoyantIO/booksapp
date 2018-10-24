# Buoyant Books App #

Sample distributed Ruby app using Sinatra, ActiveRecord, and ActiveResource.

## Running in Kubernetes ##

You can run the app in Kubernetes, using the `booksapp.yml ` config.

    $ kubectl apply -f booksapp.yml

Or, if you're using Linkerd:

    $ linkerd inject booksapp.yml | kubectl apply -f -

It takes about a minute for the app to initialize.

## Running Locally ##

Create, migrate, and seed the database:

    $ bundle install
    $ bundle exec rake db:create
    $ bundle exec rake db:migrate
    $ bundle exec rake db:seed

Start the web app:

    $  bundle exec rake dev:webapp

Start the authors app:

    $ bundle exec rake dev:authors

Start the books app:

    $ bundle exec rake dev:books

Open the website:

    $ open "http://localhost:7000"
