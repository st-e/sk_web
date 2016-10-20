# encoding: utf-8

class User < ActiveRecord::Base
	set_primary_key "username"

	# Associations
	belongs_to :person

	# Additional (non-database) fields
	attr_accessor :current_password

	# Default validations
	reserved_usernames=['root']+SpecialUser.usernames
	validates_presence_of   :username,                                :message   => "darf nicht leer sein" # length will also count blanks
	validates_uniqueness_of :username, :case_sensitive => false,      :message   => "existiert schon"
	validates_length_of     :username, :minimum => 2,                 :too_short => "muss mindestens {{count}} Zeichen lang sein"
	validates_format_of     :username, :with => /^[a-zA-Z0-9_.-]+$/,  :message   => "darf nur Buchstaben, Ziffern, _, . und - enthalten"
	validates_exclusion_of  :username, :in => reserved_usernames,     :message   => "{{value}} ist reserviert"

	# Password validation
	# On creation, we always require a password to be present. Otherwise, we
	# require that the password not be blank *if* it is present at all. That
	# way, we can have an edit form without password fields, but if there is a
	# password field (e. g. on the change password page), it must be specified.
	# In any case, if a password is given, it must match the confirmation.
	validates_presence_of     :password, :on => :create,                     :message => "darf nicht leer sein"
	validates_presence_of     :password, :allow_nil => true, :on => :update, :message => "darf nicht leer sein"
	validates_confirmation_of :password,                                     :message => "stimmt nicht mit Bestätigung überein"

	# Human names for attributes
	attr_human_name :username         => 'Benutzername'
	attr_human_name :current_password => 'Altes Passwort'
	attr_human_name :password         => 'Passwort'

	# Callbacks
	# If a password confirmation is given, a password is also given and must be
	# hashed before saving. If no password confirmation is given, no password
	# was given either, and the password attribute was not changed. In this
	# case, it contains the hash and will not be hashed.
	before_save :hash_password!, :if => :password_confirmation_given?


	def self.authenticate(username, password)
		# Try to authenticate as special user. Return true or false, continue on nil
		special_user_result=SpecialUser.authenticate(username, password)
		return special_user_result unless special_user_result.nil?

		User.exists? 'username'=>username, 'password'=>mysql_password_hash(password)
	end

	def clear_passwords
		self.password=nil
		self.password_confirmation=nil
		self.current_password=nil
	end

	def has_permission?(permission)
		return true if permission.nil?

		permission_method="perm_#{permission}"
		respond_to?(permission_method) && send(permission_method)
	end

	def self.find_by_username(*args)
		if args[0]==DatabaseUser.username
			DatabaseUser.new
		else
			super(*args)
		end
	end

	def special?
		false
	end

protected
	def hash_password!
		self.password = mysql_password_hash(self.password)
	end

	def password_confirmation_given?
		!password_confirmation.nil?
	end
end

