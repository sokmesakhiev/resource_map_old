source 'https://rubygems.org'

gem 'rails', '~> 4.1.6'
gem 'mysql2'
gem 'devise'
# gem 'haml-rails'
# gem 'decent_exposure'
# gem "instedd-rails", '0.0.17'
# gem "breadcrumbs_on_rails"
gem "tire"
gem "valium"
# gem "resque", :require => "resque/server"
# gem 'resque-scheduler', :require => 'resque_scheduler'
# gem "nuntium_api", "~> 0.13", :require => "nuntium"
# gem 'ice_cube'
# gem 'knockoutjs-rails'
# gem 'will_paginate'
# gem 'jquery-rails', "~> 2.0.2"
# gem 'foreman'
# gem 'uuidtools-offline'
gem 'rmagick', '2.13.2', :require => false
# gem 'newrelic_rpm'
# gem 'cancan'
gem 'aws-sdk'
gem 'whenever', :require => false
gem 'georuby', '2.2.1'
gem 'dbf', :require => 'dbf'
gem 'zip-zip'
gem 'rubyzip', :require => 'zip/zip'
gem "password_strength"
gem "ruby-recaptcha"
gem 'i18n-coffee'
gem 'rack-offline'


gem 'haml-rails', '~> 0.4'
gem 'gettext', '~> 3.1.2'
# gem 'gettext_i18n_rails_js', git: "https://github.com/juanboca/gettext_i18n_rails_js.git", branch: 'master'
gem 'ruby_parser', :require => false, :group => :development
gem 'haml-magic-translations'
gem 'decent_exposure'
gem "instedd-rails", '~> 0.0.24'
gem "breadcrumbs_on_rails"
# gem "elasticsearch"
# gem "elasticsearch-ruby"
gem "resque", :require => "resque/server"
gem 'resque-scheduler', '~> 3.0.0'
gem "nuntium_api", "~> 0.13", :require => "nuntium"
gem 'ice_cube'
gem 'knockoutjs-rails'
gem 'will_paginate'
gem 'jquery-rails', "~> 2.0.2"
gem 'foreman'
gem 'uuidtools'
gem 'newrelic_rpm'
gem 'cancancan', '~> 1.9'
gem "omniauth"
gem "omniauth-openid"
gem 'alto_guisso', git: "https://github.com/instedd/alto_guisso.git", branch: 'master'
gem 'oj'
gem 'carrierwave'
gem 'mini_magick'
gem 'activerecord-import'
gem 'active_model_serializers'
gem 'includes-count'
gem 'poirot_rails', git: "https://github.com/instedd/poirot_rails.git", branch: 'master' unless ENV['CI']

gem 'treetop', '1.4.15'

gem 'protected_attributes'
gem 'rails-observers'
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'
gem 'activerecord-deprecated_finders'

group :test do
  gem 'shoulda-matchers'
  gem 'ci_reporter'
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
  gem 'rvm-capistrano', '1.2.2', :require => false
  gem 'jasminerice', '~> 0.1.0', :git => 'https://github.com/bradphelan/jasminerice'
  gem 'guard-jasmine'
  # gem 'pry'
  # gem 'pry-debugger', '~>0.2.2'
end

group :development do
  gem 'dist', :git => 'https://github.com/manastech/dist.git'
  gem 'ruby-prof', :git => 'https://github.com/ruby-prof/ruby-prof.git'
  gem 'mailcatcher'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'

  gem 'sass-rails',   '~> 4.0.1'
  gem 'coffee-rails', '~> 4.0.1'

  gem 'uglifier', '>= 2.5.0'
  gem 'lodash-rails'
end

gem 'rails_12factor', group: :production