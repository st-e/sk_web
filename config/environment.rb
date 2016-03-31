# encoding: utf-8
#require 'fileutils'

# Load the rails application from application.rb
require File.expand_path('../application', __FILE__)

# If template is nil, '.dist' is appended to file
#def initialize_config_file(file, template=nil)
#	return if  File.exist? file

#	template=file+".dist" if !template
#	return if !File.exist? template

#	begin
#		print "Initializing #{file} from #{template}..."
#		# This may run as root (sudo rake gems:install), so preserve
#		FileUtils.mkdir_p File.dirname(file)
#		FileUtils.cp template, file, :preserve=>true
#	rescue Errno::EACCES
#		print "access denied"
#	ensure
#		puts
#	end
#end

# Initialize the rails application
SkWeb::Application.initialize!

#Rails::Initializer.run do |config|
#    require 'settings'

    # Some paths may be set from the environment:
    # This is relevant for installing the application to /usr/share/
    # See also initializers/session_store.rb
    # Note that some "log_tailer" still tries to access log/*.log
    #config.cache_store = :file_store, ENV['SK_WEB_CACHE']                                        if ENV['SK_WEB_CACHE']
    #config.log_path                    = File.join(ENV['SK_WEB_LOG'], "#{ENV['RAILS_ENV']}.log") if ENV['SK_WEB_LOG']
    #config.database_configuration_file = File.join(ENV['SK_WEB_ETC'], 'database.yml')            if ENV['SK_WEB_ETC']
    #Settings.configuration_file        = File.join(ENV['SK_WEB_ETC'], 'sk_web.yml')              if ENV['SK_WEB_ETC']

    # If the database configuration file does not exist, create it. This is
    # required so we can run rake gems:install even if we haven't configured the
    # database yet.
    # Also create the application configuration and the local main page.
    # TODO move to initializer?
    #initialize_config_file config.database_configuration_file, Rails.root.join('config', 'database.yml.dist').to_s
    #initialize_config_file Settings.configuration_file       , Rails.root.join('config',   'sk_web.yml.dist').to_s
    #initialize_config_file Rails.root.join('app', 'views', 'local', '_main_page.html.erb').to_s
    #config.time_zone = 'UTC'
#end