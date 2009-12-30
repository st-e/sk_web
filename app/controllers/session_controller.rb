require 'util'

class SessionController < ApplicationController
	allow_public :only => [:login, :logout]

	def login
		username=params[:username]
		password=params[:password]

		if username && password
			if User.exists? 'username'=>username, 'password'=>mysql_password_hash(password)
				# TODO da muss man das natürlich auch speichern

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
		# TODO da muss man das natürlich auch speichern
		session[:username]=nil

		flash[:notice]="Abgemeldet"
		redirect_to root_path
	end
end


