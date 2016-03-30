# encoding: utf-8

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

                # usernames is called by user.rb (reserved_usernames), so it cannot be protected
		# made public (CK, 2014-07-26)
		def usernames
			@subclasses.map { |subclass| subclass.username }
		end


		# Try to authenticate against one of the known subclasses. Returns nil
		# if no user is found and false if authentication failed
		# Called by user.rb authenticate, so it cannot be protected
		# made public (CK, 2014-07-26)
		def authenticate(username, password)
			@subclasses.each { |subclass|
				if subclass.username==username
					return subclass.check_password(password)
				end
			}
			nil
		end

		protected
		def credentials(username, password)
			@username=username
			@password=password
		end

		def inherited(subclass)
			@subclasses << subclass
		end

	end

	# Instance methods
	def username; self.class.username; end
	def has_permission?(permission); false; end
	def person_id; 0; end
	def person; nil; end
	def special?; true; end
	def club; ""; end
end

# An almighty special user using the database credentials. This is necessary
# for creating a user account initially or resetting the admin's password.
class DatabaseUser <SpecialUser
	config=Rails::Configuration.new
	credentials \
		config.database_configuration[Rails.env]["username"],
		config.database_configuration[Rails.env]["password"]

	def has_permission?(permission)
		true # :-)
	end
end

