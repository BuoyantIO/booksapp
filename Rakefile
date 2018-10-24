require 'timeout'
require 'sinatra/activerecord/rake'

namespace :db do
  task :load_config do
    require_relative 'models/author'
    require_relative 'models/book'
  end

  desc "Blocks until connection to database is available"
  task :ready do
    begin
      require 'sinatra/activerecord'
    rescue Mysql2::Error, Timeout::Error => e
      STDERR.puts "waiting for database"
      STDERR.flush
      sleep 1
      retry
    end
    STDERR.puts "database ready"
  end
end

namespace :dev do
  desc "Starts the webapp app in development mode on port 7000"
  task webapp: "db:ready" do
    sh "bundle exec ruby webapp.rb -p 7000"
  end

  desc "Starts the authors app in development mode on port 7001"
  task authors: "db:ready" do
    sh "bundle exec ruby authors.rb -p 7001"
  end

  desc "Starts the books app in development mode on port 7002"
  task books: "db:ready" do
    sh "bundle exec ruby books.rb -p 7002"
  end
end

namespace :prod do
  desc "Starts the webapp app in production mode on port 7000"
  task webapp: "db:ready" do
    sh "bundle exec ruby webapp.rb -e production -p 7000"
  end

  desc "Starts the authors app in production mode on port 7001"
  task authors: "db:ready" do
    sh "bundle exec ruby authors.rb -e production -p 7001"
  end

  desc "Starts the books app in production mode on port 7002"
  task books: "db:ready" do
    sh "bundle exec ruby books.rb -e production -p 7002"
  end
end
