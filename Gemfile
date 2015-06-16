source 'https://rubygems.org'

gem 'rails', '3.2.17'
gem 'mysql2'
gem 'devise', '2.2.4'
gem 'haml-rails'
gem 'decent_exposure'
gem "instedd-rails", '0.0.17'
gem "breadcrumbs_on_rails"
gem "tire"
gem "valium"
gem "resque", :require => "resque/server"
gem 'resque-scheduler', "~> 2.5.5", :require => 'resque_scheduler'
gem "nuntium_api", "~> 0.13", :require => "nuntium"
gem 'ice_cube'
gem 'knockoutjs-rails'
gem 'will_paginate'
gem 'jquery-rails', "~> 2.0.2"
gem 'foreman'
gem 'uuidtools'
gem 'rack-offline'
gem 'rmagick', '2.13.2', :require => false
gem 'newrelic_rpm'
gem 'cancan'
gem 'aws-sdk'
gem 'whenever', :require => false
gem 'georuby', "2.2.1"
gem 'zip-zip'
gem 'dbf', :require => 'dbf'
gem 'rubyzip', :require => 'zip/zip'
gem "password_strength"
gem "ruby-recaptcha"
gem 'i18n-coffee'
gem "omniauth"
gem "omniauth-openid"
gem 'alto_guisso', github: "instedd/alto_guisso", branch: 'master'
gem 'alto_guisso_rails', github: "instedd/alto_guisso_rails", branch: 'master'
gem 'oj'
gem 'activerecord-import'
gem 'active_model_serializers'

group :test do
  gem 'shoulda-matchers'
  gem 'ci_reporter', "1.8.4"
  gem 'selenium-webdriver'
  gem 'nokogiri'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'resque_spec'
end

group :test, :development do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'faker'
  gem 'machinist', '1.0.6'
  gem 'capistrano', '~> 2.15'
  gem 'rvm'
  gem  'rvm-capistrano',  require: false
  gem 'jasminerice'
  gem 'guard-jasmine'
  gem 'pry'
  gem 'pry-debugger', '~>0.2.2'
end

group :development do
  gem 'dist', :git => 'https://github.com/manastech/dist.git'
  gem 'ruby-prof', :git => 'https://github.com/ruby-prof/ruby-prof.git'
  gem 'mailcatcher'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
  gem 'lodash-rails'
end

gem 'rails_12factor', group: :production