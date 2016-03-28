# encoding: utf-8

class Plane < ActiveRecord::Base
	has_many :flights

	# Rails sez:
	# The single-table inheritance mechanism failed to locate the subclass:
	# 'normal'. This error is raised because the column 'type' is reserved for
	# storing the class in case of inheritance. Please rename this column if
	# you didn't intend it to be used for storing the inheritance class or
	# overwrite Flight.inheritance_column to use another column for that
	# information.
	def Plane.inheritance_column
		"class_type"
	end

	# Hack to allow a type column
	def type
		attributes['type']
	end

	
	# Categories:
	#   - airplane
	#   - glider
	#   - motorglider
	#   - ultralight
	#   - other

	#def used?
	#	!users.empty? || UnixUser.find_by_unix_group_id(id) != nil
	#end

	def glider?
		category=='glider'
	end

	def sep?
		category=='airplane'
	end

	def motorglider?
		category=='motorglider'
	end

	def ultralight?
		category=='ultralight'
	end
end

