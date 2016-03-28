# encoding: utf-8

class LaunchMethod < ActiveRecord::Base

	# Rails sez:
	# The single-table inheritance mechanism failed to locate the subclass:
	# 'normal'. This error is raised because the column 'type' is reserved for
	# storing the class in case of inheritance. Please rename this column if
	# you didn't intend it to be used for storing the inheritance class or
	# overwrite Flight.inheritance_column to use another column for that
	# information.
	def LaunchMethod.inheritance_column
		"class_type"
	end

	# Hack to allow a type column
	def type
		attributes['type']
	end


	def is_airtow?
		type=='airtow'
	end

	def towplane_known?
		!towplane_registration.blank?
	end

	def LaunchMethod.self_launch
		find_by_type 'self'
	end
end
