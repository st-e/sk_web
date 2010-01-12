require 'util'

class SessionController < ApplicationController
	allow_public :login, :logout
	require_login :settings

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
				flash[:error]="Anmeldedaten ungültig"
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

		flash[:notice]="Diagnosefunktionen #{(session[:debug])?"aktiviert":"deaktiviert"}"

		redirect_to :back
	end
end

