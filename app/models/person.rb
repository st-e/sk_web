class Person < ActiveRecord::Base
	set_table_name "person_temp" 
	 
	has_many :flights
	has_one :user, :foreign_key => 'person'

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

