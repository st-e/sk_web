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


	def current_username
		session[:username]
	end

	def current_user
		return nil if !session[:username]
		User.find(session[:username])
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
			return if local? || logged_in?

			# Have to log in
			# TODO function
			flash[:error]="Anmeldung erforderlich, da der Zugang nicht aus dem lokalen Netz erfolgt"
			store_origin request.url
			redirect_to login_path
			return
		end

		# Complain if no permissions have been set
		permissions=self.class.required_permissions_for action
		if !permissions
			render :text => "Für diese Aktion wurden keine Zugriffsrechte gesetzt"
			return
		end

		# Other actions require login
		unless logged_in?
			flash[:error]="Anmeldung erforderlich"
			store_origin request.url
			redirect_to login_path
			return
		end

		# Check permissions
		permissions.each { |permission|
			unless current_user.has_permission? permission
				flash.now[:error]="Zugriff verweigert"
				render :text=>"", :layout=>true
			end
		}
	end


	
	def logged_in?
		!!session[:username]
	end

	def local?
		# TODO read from configuration file
		request.remote_ip == "127.0.0.1"
	end
end

