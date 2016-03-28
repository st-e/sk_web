# encoding: utf-8

require_dependency 'attempt'

class UsersController < ApplicationController
	filter_parameter_logging :password # Filter parameters containing "password"
	
	require_permission :club_admin, :index, :show, :new, :create, :edit, :update, :destroy, :change_password
	require_login :change_own_password

	def index
		attempt do
			@users = User.paginate :page => params[:page], :per_page => 20, :order => 'username', :readonly=>true
			params[:page]=1 and redo if (!@users.empty? and @users.out_of_bounds?)
		end

		render "index"
	end

	def show
		@user = User.find(params[:id], :readonly=>true)
		render_error h "Der Spezialbenutzer #{@user.username} kann nicht angezeigt werden." and return if @user.special?
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
			flash[:notice] = "Der Benutzer #{@user.username} wurde angelegt."
			redirect_to @user
		else
			render :action => "new"
		end
	end

	def edit
		@user = User.find(params[:id])
		render_error h "Der Spezialbenutzer #{@user.username} kann nicht editiert werden." and return if @user.special?

		# Restore the user, if given (e. g. after returning from a subpage)
		@user.attributes=params[:user] if params[:user]

		if params[:subpage]
			# Button pressed on subpage
			if params[:commit]
				# Return from subpage
				render
			elsif params[:subpage]=='select_person'
				# Button on select person subpage
				select_person
			end
		else
			# Regular edit

			# Store the location we came from, so we can return there after editing
			store_origin
		end
	end

	# If we want to allow changing the password here, we should check
	# if the password fields have been left blank and, in this case,
	# remove them from the params hash.
	def update
		# Button press on edit page

		# Read the user and update the attributes (don't save at this point)
		@user = User.find(params[:id])
		render_error h "Der Spezialbenutzer #{@user.username} kann nicht editiert werden." and return if @user.special?
		@user.attributes=params[:user] if params[:user]

		# Subpages
		select_person and return if params['select_person']

		if params['commit']
			# 'Save' button
			render 'edit' and return if !@user.save

			flash[:notice] = "Der Benutzer #{@user.username} wurde gespeichert."
			redirect_to_origin(default=@user)
			return
		end

		render 'edit'
	end

	def select_person
		page=page_parameter

		attempt do
			@people = Person.paginate :page => page, :per_page => 20, :order => 'last_name, first_name', :readonly=>true
			params[:page]=1 and redo if @people.out_of_bounds?
		end

		render 'select_person'
	end

	def destroy
		@user = User.find(params[:id])
		render_error h "Der Spezialbenutzer #{@user.username} kann nicht gelöscht werden." and return if @user.special?
		render_error h "Der Benutzer #{current_username} kann sich nicht selbst löschen." and return if @user.username==current_username

		@user.destroy

		flash[:notice]="Der Benutzer #{@user.username} wurde gelöscht."
		redirect_to(users_url)
	end

	def change_password
		@user = User.find(params[:id])
		@display_old_password_field=false

		render_error h "Das Passwort des Spezialbenutzers #{@user.username} kann nicht geändert werden." and return if @user.special?

		if params[:user]
			@user.attributes=params[:user]
			if @user.save
				flash[:notice] = "Der Passwort des Benutzers #{@user.username} wurde geändert"
				redirect_to @user
			end
		end

		# default: render
	end

	def change_own_password
		@user=current_user(readonly=false)
		@display_current_password_field=true
		@no_links=true

		render_error h "Das Passwort des Spezialbenutzers #{@user.username} kann nicht geändert werden." and return if @user.special?

		if params[:user]
			if User.authenticate(@user.username, params[:user][:current_password])
				@user.attributes=params[:user]

				if @user.save
					flash[:notice] = 'Passwort geändert'
					redirect_to root_path
				end
			else
				@user.errors.add(:current_password, "ist nicht korrekt")
			end
		end

		render 'change_password' if !performed?
	end
end

