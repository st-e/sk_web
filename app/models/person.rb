class Person < ActiveRecord::Base
	set_table_name "person_temp" 
	 
	has_one :user, :foreign_key => 'person'

	# TODO:
	#validates_uniqueness_of :club_id, :scope => :club

	# TODO replace all
	alias_attribute :last_name , :nachname
	alias_attribute :first_name, :vorname
	alias_attribute :club      , :verein
	alias_attribute :club_id   , :vereins_id
	alias_attribute :comments  , :bemerkung

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
		# Don't allow destruction of people which are in use
		return if used?
		super
	end

	def used?
		User  .exists?(:person    =>id)||
		Flight.exists?(:pilot     =>id)||
		Flight.exists?(:begleiter =>id)||
		Flight.exists?(:towpilot  =>id)
	end
	
	 #validates_presence_of :name, :title
	 #validates_length_of :title, :minimum => 5 
end

