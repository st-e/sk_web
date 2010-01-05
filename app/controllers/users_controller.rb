require 'util'

class UsersController < ApplicationController
	filter_parameter_logging :password1, :password2

	def index
		@users = User.all(:order => "username")
		render "index"
	end

	def show
		@user = User.find(params[:id])
		render "show"
	end

	def new
		@user = User.new
	end

	def create
		@user = User.new(params[:user])

		username=params[:user][:username]
		password1=params[:password1]
		password2=params[:password2]

		@user.username=params[:user][:username]

		if username.blank?
			flash.now[:error] = 'Benutzername darf nicht leer sein'
			render :action => "new"
		elsif !(username =~ /^[a-zA-Z0-9_.-]*$/)
			flash.now[:error] = 'Benutzername enthält ungültige Zeichen'
			render :action => "new"
		elsif User.exists?(username)
			flash.now[:error] = 'Benutzername existiert schon'
			render :action => "new"
		elsif password1.blank?
			flash.now[:error] = 'Passwort darf nicht leer sein'
			render :action => "new"
		elsif password1!=password2
			flash.now[:error] = 'Passwörter stimmen nicht überein'
			render :action => "new"
		else
			@user.password=mysql_password_hash(password1)

			if @user.save
				flash[:notice] = 'Benutzer wurde angelegt'
				redirect_to @user
			else
				render :action => "new"
			end
		end
	end

	def edit
		# TODO: if multiple edit windows are opened, all of them will redirect
		# back to the origin of the last one
		session[:origin]=request.referer
		@user = User.find(params[:id])

		# If a user parameter is given, we've probably returned from a subpage.
		@user.attributes=params[:user] if params[:user]
	end

	def update
		@user = User.find(params[:id])

		if params['commit']
			if @user.update_attributes(params[:user])
				flash[:notice] = 'Benutzer wurde gespeichert'

				# TODO: make function
				# TODO: doesn't work after person selection
				if session[:origin]
					redirect_to session[:origin]
					session[:origin]=nil
				else
					redirect_to(@user)
				end
			else
				render :action => "edit"
			end
		elsif params['select_person']
			@user.attributes=params[:user]
			@people = Person.all(:order => "nachname, vorname")
			render 'select_person'
		end
	end

	def destroy
		@user = User.find(params[:id])
		@user.destroy

		redirect_to(users_url)
	end

	def change_password
		@user = User.find(params[:id])
		@display_old_password=false

		password1=params[:password1]
		password2=params[:password2]
		
		if password1 && password2
			if password1!=password2
				flash.now[:error] = 'Passwörter stimmen nicht überein'
				render
			elsif password1.blank?
				flash.now[:error] = 'Passwort darf nicht leer sein'
				render
			else
				@user.password=mysql_password_hash(password1)

				if @user.save
					flash[:notice] = 'Passwort wurde geändert'
					redirect_to @user
				else
					render
				end
			end
		else
			render
		end
	end
end

