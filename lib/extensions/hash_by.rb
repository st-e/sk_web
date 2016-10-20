# encoding: utf-8

# http://flowcoder.com/65

# I created these Array extensions for handling the common case of creating a
# hash lookup for members of an array -- saves me from having to fumble around
# with inject, and keeps things concise and readable:
# 
# Before:
#   @users_by_city = @users.inject({}) do |hsh, user|
#     current_for_city = hsh[user.city] || []
#     hsh[user.city] = current_for_city << user
#     hsh
#   end
#
# After:
#   @users_by_city = @users.array_hash_by :city

class Array
	# Create a hash where the keys are the result of either sending method_for_key or 
	# calling supplied block on each member, and the values are the corresponding
	# members of the hashed array
	#
	# Examples:
	#   users = [{'name' => 'Ralf', 'city' => 'Berlin'}, 
	#           {'name' => 'Florian', 'city' => 'Dusseldorf'}, 
	#           {'name' => 'Karlos', 'city' => 'Berlin'}]
	#
	#   users.hash_by :object_id       # =>  {30140=>{"city"=>"Berlin", "name"=>"Karlos"}, 
	#                                         30190=>{"city"=>"Dusseldorf", "name"=>"Florian"}, 
	#                                         30240=>{"city"=>"Berlin", "name"=>"Ralf"}}
	#
	#   users.hash_by {|u| u['name']}  # => {"Florian"=>{"city"=>"Dusseldorf", "name"=>"Florian"}, 
	#                                       "Karlos"=>{"city"=>"Berlin", "name"=>"Karlos"}, 
	#                                       "Ralf"=>{"city"=>"Berlin", "name"=>"Ralf"}}
	#
	# If more than one member has the same key value, the last one in will be retained, and
	# previous entries will be lost. See Array#array_hash_by for a way to hash multiple
	# members with the same key
	def hash_by(method_for_key = nil)
		inject({}) do |hsh, obj| 
			key = block_given? ? yield(obj) : obj.send(method_for_key)
			hsh[key] = obj
			hsh
		end
	end

	# Create a hash where the keys are the result of either sending method_for_key or 
	# calling supplied block on each member, and the values are arrays of the 
	# corresponding members of the hashed array
	#
	# Example:
	#   users = [{'name' => 'Ralf', 'city' => 'Berlin'}, 
	#           {'name' => 'Florian', 'city' => 'Dusseldorf'}, 
	#           {'name' => 'Karlos', 'city' => 'Berlin'}]
	#
	#   users.array_hash_by {|u| u['city']}  # => {"Berlin"=>[{"city"=>"Berlin", "name"=>"Ralf"}, 
	#                                                         {"city"=>"Berlin", "name"=>"Karlos"}], 
	#                                             "Dusseldorf"=>[{"city"=>"Dusseldorf", "name"=>"Florian"}]}
	def array_hash_by(method_for_key = nil)
		inject({}) do |hsh, obj| 
			key = block_given? ? yield(obj) : obj.send(method_for_key)
			hsh[key] = (hsh[key] || []) << obj
			hsh
		end
	end
end

