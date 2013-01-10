source 'https://rubygems.org'

gem 'rails', '3.2.11'
gem 'mysql2'
gem 'devise'
gem 'haml-rails'
gem 'decent_exposure'
gem "instedd-rails", '0.0.17'
gem "breadcrumbs_on_rails"
gem "tire"
gem "valium"
gem "resque", :require => "resque/server"
gem 'resque-scheduler', :require => 'resque_scheduler'
gem "nuntium_api", "~> 0.13", :require => "nuntium"
gem 'ice_cube'
gem 'knockoutjs-rails'
gem 'will_paginate'
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :test, :development do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'faker'
  gem 'machinist', '1.0.6'
  gem 'capistrano'
  gem 'rvm'
  gem 'rvm-capistrano', '1.2.2'
  gem 'jasminerice'
  gem 'guard'
  gem 'guard-jasmine'
  gem 'guard-rspec'
  gem 'spork'
  gem 'guard-spork'
end

group :test do
  gem 'shoulda-matchers'
  gem 'ci_reporter'
  gem 'resque_spec'
  gem 'pry'
  gem 'pry-nav'

  gem 'rb-fsevent', :require => RUBY_PLATFORM.include?('darwin') && 'rb-fsevent'
  gem 'rb-inotify', :require => RUBY_PLATFORM.include?('linux') && 'rb-inotify'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the web server
# gem 'unicorn'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

gem 'foreman'
