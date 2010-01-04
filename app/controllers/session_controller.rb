require 'util'

class SessionController < ApplicationController
	allow_public :only => [:login, :logout]

	filter_parameter_logging :password, :old_password, :password1, :password2

	def login
		username=params[:username]
		password=params[:password]

		if username && password
			if authenticate(username, password)
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

	def change_password
		@user=current_user
		@display_old_password=true
		template='users/change_password'

		old_password=params[:old_password]
		new_password_1=params[:password1]
		new_password_2=params[:password2]

		if old_password && new_password_1 && new_password_2
			if old_password.blank?
				flash.now[:error] = 'Altes Passwort nicht angegeben'
				render template
			elsif !authenticate(current_username, old_password)
				flash.now[:error] = 'Altes Passwort ist nicht korrekt'
				render template
			elsif new_password_1!=new_password_2
				flash.now[:error] = 'Passwörter stimmen nicht überein'
				render template
			elsif new_password_1.blank?
				flash.now[:error] = 'Passwort darf nicht leer sein'
				render template
			else
				@user.password=mysql_password_hash(new_password_1)

				if @user.save
					flash[:notice] = 'Passwort wurde geändert'
					redirect_to root_path
				else
					render template
				end
			end
		else
			render template
		end
	end

protected
	def authenticate(username, password)
		User.exists? 'username'=>username, 'password'=>mysql_password_hash(password)
	end
end


