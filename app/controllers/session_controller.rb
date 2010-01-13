require 'util'

class SessionController < ApplicationController
	allow_public :login, :logout, :settings

	filter_parameter_logging :current_password, :password, :password_confirmation

	def login
		# TODO require post, see akaportal:portal_controller

		username=params[:username]
		password=params[:password]

		if username && password
			if User.authenticate(username, password)
				# TODO reset session
				session[:username]=username

				flash[:notice]="Angemeldet als #{username}"

				# The page we tried to access is stored as the origin
				redirect_to_origin(default=root_path)
			else
				flash[:error]="Die angegebenen Anmeldedaten sind nicht korrekt."
				@username=username
				render
			end
		else
			render
		end
	end

	def logout
		# TODO reset session
		session[:username]=nil

		flash[:notice]="Abgemeldet"
		redirect_to root_path
	end

	def settings
		session[:debug]=params[:debug].to_b

		flash[:notice]="Die Diagnosefunktionen wurden #{(session[:debug])?"aktiviert":"deaktiviert"}."

		# It's hard to get the redirect right, especially if we're deactivating
		# the debug functions from the redirect page after activating them - it
		# will redirect :back to activate them.
		# TODO make better, so turning it off from the redirect page does not
		# redirect to root
		#redirect_to :back
		redirect_to root_path
	end
end

