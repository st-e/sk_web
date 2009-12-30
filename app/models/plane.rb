class Plane < ActiveRecord::Base
	set_table_name "flugzeug_temp" 

	has_many :flights
	
#	def used?
#      !users.empty? || UnixUser.find_by_unix_group_id(id) != nil
#    end
end
