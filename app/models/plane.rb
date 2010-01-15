class Plane < ActiveRecord::Base
	set_table_name "flugzeug_temp" 

	has_many :flights
	
	# Categories:
	# e: SEP
	# 1: glider
	# k: motorglider
	# m: ultralight
	# s: other
	# -: none

	#def used?
	#	!users.empty? || UnixUser.find_by_unix_group_id(id) != nil
	#end

	def glider?
		gattung=='1'
	end

	def sep?
		gattung=='e'
	end

	def motorglider?
		gattung=='k'
	end

	def ultralight?
		gattung=='m'
	end
end

