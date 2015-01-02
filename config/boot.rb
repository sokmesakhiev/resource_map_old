require 'rubygems'
require 'yaml'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

module Settings
  extend self

  CONFIG = YAML.load_file(File.expand_path('../settings.yml', __FILE__))

  def is_on?(plugin)
    plugins[plugin.to_s] == true
  end

  def selected_plugins
    plugins.map{|k,v| k if v == true }.compact
  end

  def method_missing(method_name)
    if method_name.to_s =~ /(\w+)\?$/
      CONFIG[$1] == true
    else
      CONFIG[method_name.to_s]
    end
  end
end

module RecaptchaSetting
  extend self

  CONFIG = YAML.load_file(File.expand_path('../recaptcha.yml', __FILE__))

  def method_missing(method_name)
    if method_name.to_s =~ /(\w+)\?$/
      CONFIG[Rails.env][$1] == true
    else
      CONFIG[Rails.env][method_name.to_s]
    end
  end
  
  def validate_captcha(key, challeng, response)
    uri = URI('http://www.google.com/recaptcha/api/verify')
    params = { :privatekey => key, :remoteip => Settings.host, :challenge => challeng, :response => response }
    res = Net::HTTP.post_form(uri, params)
  end

end

