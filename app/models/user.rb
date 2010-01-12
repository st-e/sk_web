# A user which is not read from the database.
# Implementations must set the variables @username and @password of the
# subclass.
class SpecialUser
	# Class methods

	class << self
		attr_reader :username

		def check_password(password)
			@password && password==@password
		end

		protected
		def credentials(username, password)
			@username=username
			@password=password
		end
	end

	# Instance methods
	def username; self.class.username; end
	def has_permission?(permission); false; end
	def person; 0; end
	def associated_person; nil; end
	def special?; true; end
end

# A special user using the database credentials. This is necessary for creating
# a user account initially or resetting the admin's password.
class DatabaseUser <SpecialUser
	config=Rails::Configuration.new
	credentials \
		config.database_configuration[RAILS_ENV]["username"],
		config.database_configuration[RAILS_ENV]["password"]

	def has_permission?(permission)
		true # :-)
	end
end

class User < ActiveRecord::Base
	# Table settings
	set_table_name "user" 
	set_primary_key "username"

	# Associations
	# It's called associated_person rather than person because the attribute
	# name should be different from the foreign key. Otherwise, we could not
	# distinguish between accesses to the attribute and to the key.
	# TODO rename to the_person, consistent with Flight
	belongs_to :associated_person, :class_name => "Person", :foreign_key => 'person'

	# Additional (non-database) fields
	attr_accessor :current_password

	# Default validations
	validates_presence_of   :username,                                :message   => "darf nicht leer sein" # length will also count blanks
	validates_uniqueness_of :username, :case_sensitive => false,      :message   => "existiert schon"
	validates_length_of     :username, :minimum => 2,                 :too_short => "muss mindestens {{count}} Zeichen lang sein"
	validates_format_of     :username, :with => /^[a-zA-Z0-9_.-]*$/,  :message   => "Der Benutzername darf nur Buchstaben, Ziffern, _, . und - enthalten"
	validates_exclusion_of  :username, :in => ['root', DatabaseUser.username], :message => "{{value}} ist reserviert"

	# Password validation
	# On creation, we always require a password to be present. Otherwise, we
	# require that the password not be blank *if* it is present at all. That
	# way, we can have an edit form without password fields, but if there is a
	# password field (e. g. on the change password page), it must be specified.
	# In any case, if a password is given, it must match the confirmation.
	validates_presence_of     :password, :on => :create,     :message => "darf nicht leer sein"
	validates_presence_of     :password, :allow_nil => true, :message => "darf nicht leer sein"
	validates_confirmation_of :password,                     :message => "stimmt nicht mit Bestätigung überein"

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
		if username==DatabaseUser.username
			DatabaseUser.check_password password
		else
			User.exists? 'username'=>username, 'password'=>mysql_password_hash(password)
		end
	end

	def clear_passwords
		self.password=nil
		self.password_confirmation=nil
		self.current_password=nil
	end

	def has_permission?(permission)
		send "perm_#{permission}"
	end

	def self.find(*args)
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

