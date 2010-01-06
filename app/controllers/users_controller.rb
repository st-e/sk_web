require 'util'

class UsersController < ApplicationController
	filter_parameter_logging :current_password, :password, :password_confirmation

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

		# The primary key is not read from the parameters automatically
		@user.username=params[:user][:username]

		if @user.save
			flash[:notice] = 'Benutzer wurde angelegt'
			redirect_to @user
		else
			# Do not include the clear text password in the HTML file
			@user.password=@user.password_confirmation=nil
			render :action => "new"
		end
	end

	def edit
		session[:origin]=request.referer
		@user = User.find(params[:id])

		# If a user parameter is given, we've probably returned from a subpage.
		@user.attributes=params[:user] if params[:user]
	end

	def update
		@user = User.find(params[:id])

		if params['commit']
			# Store the user

			# If we want to allow changing the password here, we should check
			# if the password fields have been left blank and, in this case,
			# remove them from the params hash.

			if @user.update_attributes(params[:user])
				flash[:notice] = 'Benutzer wurde gespeichert'

				# TODO: doesn't work after person selection
				redirect_to_origin(@user)
			else
				render :action => "edit"
			end
		elsif params['select_person']
			# Go to the "select person" page
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
		@display_old_password_field=false

		if params[:user]
			@user.attributes=params[:user]
			if @user.save
				flash[:notice] = 'Passwort wurde geändert'
				redirect_to @user
			else
				# Do not include the clear text password in the HTML file
				@user.clear_passwords
				render
			end
		else
			# Do not include the hashed password in the HTML file
			@user.clear_passwords
			render
		end
	end

	def change_own_password
		template='change_password'

		@user=current_user
		@display_current_password_field=true

		if params[:user]
			if User.authenticate(@user.username, params[:user][:current_password])
				@user.attributes=params[:user]

				if @user.save
					flash[:notice] = 'Passwort wurde geändert'
					redirect_to root_path
				else
					# Do not include the clear text password in the HTML file
					@user.clear_passwords
					render template
				end
			else
				@user.errors.add(:current_password, "ist nicht korrekt")
				@user.clear_passwords
				render template
			end

		else
			# Do not include the hashed password in the HTML file
			@user.clear_passwords
			render template
		end
	end
end

