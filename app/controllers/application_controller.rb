# encoding: utf-8

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# Hack
# Don't output anything, it adds extra output to script/runner invocations
#puts "Loading extensions"
Dir[File.join(Rails.root, "lib", "extensions", "*.rb")].each {|l| require_dependency l }

class ApplicationController < ActionController::Base
	include Rendering
	include DateHandling
	include ERB::Util

	class DummyError <Exception
	end

	#class ErrorMessage <Exception
	#	attr_accessor :message
	#
	#	def initialize(message)
	#		@message=message
	#	end
	#end


	helper :all # include all helpers, all the time
	protect_from_forgery # See ActionController::RequestForgeryProtection for details

	# Note that multiple filter_parameter_logging will override earlier ones.
	filter_parameter_logging :password

	before_filter :set_relative_url_root
	before_filter :check_permissions
	before_filter :require_ssl

	after_filter :set_pragma_public

	def set_pragma_public
		# Internet explorer requires special treatment
		if request.env['HTTP_USER_AGENT'] =~ /msie/i
			headers['Pragma'] = 'public'
		end
	end

	#rescue_from(ErrorMessage) { |ex|
	#	render_error h(ex.message)
	#}

	rescue_from(DummyError) { |ex|
		render_error h("DummyError wurde ausgelöst")
	}

	# Handle exceptions during rendering like other exceptions
	rescue_from(ActionView::TemplateError) { |ex|
		raise ex.original_exception
	}

	rescue_from(ActionController::InvalidAuthenticityToken) { |ex|
		flash[:error]="Die Anmeldung ist fehlgeschlagen. Sind Cookies aktiviert?"
		render 'session/login'
	}

	def current_username
		session[:username]
	end

	def current_user(readonly=true)
		return nil if !session[:username]
		User.find_by_username(session[:username], :readonly=>readonly)
	end

	def page_parameter
		return params[:page] if params[:page]

		page_param=params.keys.find { |key| key.starts_with?('page_') }
		return page_param.gsub('page_', '') if page_param

		nil
	end

	# Add additional information to the log block
	def log_processing
		super

        if logger && logger.info?
			logger.info("  username: #{session[:username].inspect}")
        end
	end
	

protected
	def self.inherited(subclass)
		subclass.instance_variable_set :@public_actions, []
		subclass.instance_variable_set :@local_actions, []
		subclass.instance_variable_set :@required_permissions, {}
		super
	end

	# The specified actions can be accessed without logging in, or regardless
	# of the user's permissions if a user is logged in. This overrides any
	# require_login or require_permissions specifications.
	def self.allow_public(*actions)
		@public_actions += actions.map { |action| action.to_sym }
	end

	# The specified actions can be accessed without being logged in if the
	# connection is made from a local host, or regardless of the user's
	# permissions if a user is logged in. This overrides any require_login or
	# require_permission specifications.
	def self.allow_local(*actions)
		@local_actions += actions.map { |action| action.to_sym }
	end

	# The specified actions can be accessed regardless of the user's
	# permissions, but require a user to be logged in.
	def self.require_login(*actions)
		actions.each { |action|
			@required_permissions[action.to_sym] ||= []
		}
	end

	# The specified actions require the specified permission. If there are
	# multiple require_permission statements, all permissions are required.
	# Note that if no access specification (allow_public, allow_local,
	# require_login or require_permission) is given for an action, an error
	# message is rendered if the method is accessed.
	def self.require_permission(permission, *actions)
		actions.each { |action|
			@required_permissions[action.to_sym] ||= []
			@required_permissions[action.to_sym] << permission.to_sym if permission
		}
	end

	def redirect_to_full_url(url, status)
		if session[:debug]
			@target_url=url
			@status=status

			# If there is a format parameter, the layout is not used, even when
			# :layout=>true is specified.
			params['original_format']=params[:format]
			params.delete :format

			render 'debug/redirect.html', :layout=>true
		else
			super url, status
		end
	end

	def render_if_allowed(template, format, filename, options={})
		#render_error "du kommst hier nicht rein" and return

		if format_available? format
			if (format=='pdf')
				# PDF is special
				@faux_template=template
				@page_layout=options[:page_layout]
				render 'layouts/faux_layout'
			else
				render template
			end

			set_filename filename
		else
			render_permission_denied
		end
	end


private
	def self.public_action?(action)
		@public_actions.include? action
	end

	def self.local_action?(action)
		@local_actions.include? action
	end

	def self.required_permissions_for(action)
		@required_permissions[action]
	end

	def set_relative_url_root
		ActionController::Base.relative_url_root=request.env['HTTP_X_RAILS_RELATIVE_URL_ROOT'] if request.env['HTTP_X_RAILS_RELATIVE_URL_ROOT']
	end

	def check_permissions
		action=params['action'].to_sym

		# Public actions are allowed unconditionally
		return if self.class.public_action? action

		# Local actions are allowed for local or logged-in users
		if self.class.local_action?(action)
			# Allow without permission check if we are local or logged in
			return if local_network? || logged_in?

			# Have to log in
			redirect_to_login "Anmeldung erforderlich, da der Zugang nicht aus dem lokalen Netz erfolgt"  and return
		end

		# Complain if no permissions have been set
		permissions=self.class.required_permissions_for action
		render_error(h("Fehler: Für diese Aktion wurden keine Zugriffsrechte gesetzt.")) and return if !permissions

		# Other actions require login
		redirect_to_login and return unless logged_in?

		# Check permissions
		permissions.each { |permission|
			require_permission permission
		}
	end

	def require_permission(permission)
		if current_user.has_permission? permission
			yield if block_given?
		else
			render_error(h("Der Benutzer #{current_user.username} verfügt nicht über die Berechtigung \"#{permission}\", die für diese Aktion erforderlich ist."))
		end
	end

	def render_permission_denied
		render_error h("Zugriff verweigert")
	end

	# Filter that redirects to SSL unless the request comes from a local address
	def require_ssl
		return if request.ssl?
		return if local_request? # Don't require SSL from localhost
		return if RAILS_ENV=='development' # Don't require SSL in development mode

		# Old: loses the format (try loading http://.../today.pdf) in production mode
		#redirect_to :protocol => "https://"

		# New:
		# Fails miserably - https://xxx/startkladde redirects to http://xxx/.
		# Maybe a problem with a newer rails version? This should have been
		# noticed before.
		# Note also that if someone POSTs a form with http, he'll probably get
		# a GET redirect with the parameters (bad for passwords). OTOH, this
		# should not happen normally because the forms are all https.
		#redirect_to(params.merge({:protocol => 'https://'})) and flash.keep

		# Taken from the ssl_requirement gem. TODO use ssl_requirement
		redirect_to("https://" + request.host + request.request_uri) and flash.keep

		# Literature:
		# http://stackoverflow.com/questions/1662262/rails-redirect-with-https
		# http://blog.luckyus.net/2008/07/09/ruby-on-rails-redirect-to-a-secure-page-ssl/
	end

	
	def logged_in?
		!!session[:username]
	end

	# Note that this is different from local_request: this denotes "local
	# networks", as in "no login required from here". local_request? denotes
	# localhost, as in "no SSL required from here".
	def local_network?
		Settings.instance.address_is_local? request.remote_ip
	end
end

