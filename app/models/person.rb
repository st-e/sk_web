class Person < ActiveRecord::Base
	# Table settings
	set_table_name "person_temp" 
	 
	# Associations
	has_one :user, :foreign_key => 'person'
	# TODO has_many :flights, :foreign_key => 'pilot' and also begleiter und
	# towpilot, then use flights.count in used?

	# Attribute aliases
	alias_attribute :last_name , :nachname
	alias_attribute :first_name, :vorname
	alias_attribute :club      , :verein
	alias_attribute :club_id   , :vereins_id
	alias_attribute :comments  , :bemerkung

	# Validations
	# The club ID must be unique within the club unless it is empty or no club
	# is given.
	validates_uniqueness_of :vereins_id, :scope => :verein, :if => :club_and_club_id_present,
		:message => 'ist in diesem Verein schon vergeben (und nicht leer)' # TODO für (Name) vergeben

	# Human names for attributes
	attr_human_name :verein     => 'Verein'
	attr_human_name :vereins_id => 'Vereins-ID'

	# Callbacks
	# Prevent destruction of people that are in use.
	before_destroy :ensure_not_used


	def full_name(with_nickname=false)
		if with_nickname
			"#{vorname} \"#{spitzname}\" #{nachname}"
		else
			"#{vorname} #{nachname}"
		end
	end

	def formal_name
		"#{nachname}, #{vorname}"
	end

	def destroy
		# Don't allow destruction of people which are in use; this is already
		# handled by the before_destroy callback, but this is really important.
		# TODO raise a mean exception
		return if used?
		super
	end

	def used?
		User  .exists?(:person    =>id)||
		Flight.exists?(:pilot     =>id)||
		Flight.exists?(:begleiter =>id)||
		Flight.exists?(:towpilot  =>id)
	end
	

	def club_and_club_id_present
		!club.blank? and !club_id.blank?
	end

protected
	def ensure_not_used
		if used?
			errors.add_to_base "Person wird nocht benutzt"
			return false # return exactly false
		end
	end
end

