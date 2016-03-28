# encoding: utf-8

require 'fileutils'

# Be sure to restart your server when you modify this file


# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '~>2.3.9' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')



# If template is nil, '.dist' is appended to file
def initialize_config_file(file, template=nil)
	return if  File.exist? file

	template=file+".dist" if !template
	return if !File.exist? template

	begin
		print "Initializing #{file} from #{template}..."
		# This may run as root (sudo rake gems:install), so preserve
		FileUtils.mkdir_p File.dirname(file)
		FileUtils.cp template, file, :preserve=>true
	rescue Errno::EACCES
		print "access denied"
	ensure
		puts
	end
end

Rails::Initializer.run do |config|
	require 'settings'

	# Some paths may be set from the environment:
	# This is relevant for installing the application to /usr/share/
	# See also initializers/session_store.rb
	# Note that some "log_tailer" still tries to access log/*.log
	config.cache_store = :file_store, ENV['SK_WEB_CACHE']                                        if ENV['SK_WEB_CACHE']
	config.log_path                    = File.join(ENV['SK_WEB_LOG'], "#{ENV['RAILS_ENV']}.log") if ENV['SK_WEB_LOG']
	config.database_configuration_file = File.join(ENV['SK_WEB_ETC'], 'database.yml')            if ENV['SK_WEB_ETC']
	Settings.configuration_file        = File.join(ENV['SK_WEB_ETC'], 'sk_web.yml')              if ENV['SK_WEB_ETC']


	# If the database configuration file does not exist, create it. This is
	# required so we can run rake gems:install even if we haven't configured the
	# database yet.
	# Also create the application configuration and the local main page.
	# TODO move to initializer?
	initialize_config_file config.database_configuration_file, Rails.root.join('config', 'database.yml.dist').to_s
	initialize_config_file Settings.configuration_file       , Rails.root.join('config',   'sk_web.yml.dist').to_s
	initialize_config_file Rails.root.join('app', 'views', 'local', '_main_page.html.erb').to_s

	# Settings in config/environments/* take precedence over those specified here.
	# Application configuration should go into files in config/initializers
	# -- all .rb files in that directory are automatically loaded.

	# Add additional load paths for your own custom dirs
	# config.load_paths += %W( #{RAILS_ROOT}/extras )

	# Specify gems that this application depends on and have them installed with rake gems:install
	# config.gem "bj"
	# config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
	# config.gem "sqlite3-ruby", :lib => "sqlite3"
	# config.gem "aws-s3", :lib => "aws/s3"

	#config.gem 'will_paginate', :version => '~> 2.3.11'#, :source => 'http://gemcutter.org'
	# If there are problems with PDF rendering, try setting this to '= 0.8.4', or
	# read the Prawn change log.
	#config.gem 'prawn', :version => '~> 0.8.4'

	# This is a dependency of Rails, but is looks like it's not getting unpacked
	#config.gem 'rack', :version => '~> 1.1.0'

	# We do not require the fcgi and mysql gems here because
	#   - they have a native component and thus cannot be unpacked
	#   - they are available as a package (at least in Ubuntu)
	# Also, for fcgi is not required for running with mongrel
	#config.gem 'fcgi'
	#config.gem 'mysql'

	# Only load the plugins named here, in the order given (default is alphabetical).
	# :all can be used as a placeholder for all plugins not explicitly named
	# config.plugins = [ :exception_notification, :ssl_requirement, :all ]

	# Skip frameworks you're not going to use. To use Rails without a database,
	# you must remove the Active Record framework.
	# config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

	# Activate observers that should always be running
	# config.active_record.observers = :cacher, :garbage_collector, :forum_observer

	# Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
	# Run "rake -D time" for a list of tasks for finding time zone names.
	config.time_zone = 'UTC'

	# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
	# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
	# config.i18n.default_locale = :de
	
end

