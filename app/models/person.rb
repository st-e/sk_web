class Person < ActiveRecord::Base
	set_table_name "person_temp" 
	 
	has_many :flights
	has_one :user, :foreign_key => 'person'

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
	
	 #validates_presence_of :name, :title
	 #validates_length_of :title, :minimum => 5 
end

