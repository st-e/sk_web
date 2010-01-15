# A user which is not read from the database. Implementations must set the user
# name and password using the credentials method.
class SpecialUser
	# Class methods
	@subclasses=[]

	class << self
		attr_reader :username

		def check_password(password)
			@password && (password==@password)
		end

		protected
		def credentials(username, password)
			@username=username
			@password=password
		end

		def inherited(subclass)
			@subclasses<<subclass
		end

		def usernames
			@subclasses.map { |subclass| subclass.username }
		end

		# Try to authenticate against one of the known subclasses. Returns nil
		# if no user is found and false if authentication failed
		def authenticate(username, password)
			@subclasses.each { |subclass|
				if subclass.username==username
					return subclass.check_password(password)
				end
			}
			nil
		end
	end

	# Instance methods
	def username; self.class.username; end
	def has_permission?(permission); false; end
	def person; 0; end
	def associated_person; nil; end
	def special?; true; end
	def club; ""; end
end

# An almighty special user using the database credentials. This is necessary
# for creating a user account initially or resetting the admin's password.
class DatabaseUser <SpecialUser
	config=Rails::Configuration.new
	credentials \
		config.database_configuration[RAILS_ENV]["username"],
		config.database_configuration[RAILS_ENV]["password"]

	def has_permission?(permission)
		true # :-)
	end
end

