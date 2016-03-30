require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module SkWeb
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Some paths may be set from the environment:
    # This is relevant for installing the application to /usr/share/
    # See also initializers/session_store.rb
    # Note that some "log_tailer" still tries to access log/*.log
    #config.cache_store = :file_store, ENV['SK_WEB_CACHE']                                        if ENV['SK_WEB_CACHE']
    #config.log_path                    = File.join(ENV['SK_WEB_LOG'], "#{ENV['RAILS_ENV']}.log") if ENV['SK_WEB_LOG']
    #config.database_configuration_file = File.join(ENV['SK_WEB_ETC'], 'database.yml')            if ENV['SK_WEB_ETC']
    #Settings.configuration_file        = File.join(ENV['SK_WEB_ETC'], 'sk_web.yml')              if ENV['SK_WEB_ETC']
  end
end
