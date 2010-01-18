# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
	include Rendering
	include DateHandling

	helper :all # include all helpers, all the time
	protect_from_forgery # See ActionController::RequestForgeryProtection for details

	# Note that multiple filter_parameter_logging will override earlier ones.
	filter_parameter_logging :password

	before_filter :check_permissions
	before_filter :require_ssl

	


	def current_username
		session[:username]
	end

	def current_user(readonly=true)
		return nil if !session[:username]
		User.find(session[:username], :readonly=>readonly)
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
		render_error ("Fehler: Für diese Aktion wurden keine Zugriffsrechte gesetzt.") and return if !permissions

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
			render_error("Der Benutzer #{current_user.username} verfügt nicht über die Berechtigung \"#{permission}\", die für diese Aktion erforderlich ist.")
		end
	end

	def render_permission_denied
		render_error "Zugriff verweigert"
	end

	# Filter that redirects to SSL unless the request comes from a local address
	def require_ssl
		return if local_request? # Don't require SSL from localhost
		return if RAILS_ENV=='development' # Don't require SSL in development mode

		redirect_to :protocol => "https://" and flash.keep unless request.ssl?
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

