require 'util'

class SessionController < ApplicationController
	allow_public :only => [:login, :logout]

	filter_parameter_logging :current_password, :password, :password_confirmation

	def login
		username=params[:username]
		password=params[:password]

		if username && password
			if User.authenticate(username, password)
				# TODO reset session
				session[:username]=username

				flash[:notice]="Angemeldet als #{username}"

				if session[:origin]
					redirect_to session[:origin]
					session[:origin]=nil
				else
					redirect_to root_path
				end
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
end

