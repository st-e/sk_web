require 'date'
require 'digest/sha1'

# This breaks the server
#class Array
#	def [](index)
#		return nil if index.nil?
#		super(index)
#	end
#end

class Time
	def date
		Date.new(year, month, day)
	end
end

module Comparable
	# 10.min(5) == 5
	def min(x)
		x && x < self ? x : self
	end

	# 10.max(5) == 10
	def max(x)
		x && x > self ? x : self
	end
end

def mysql_password_hash(password)
	"*#{Digest::SHA1.hexdigest(Digest::SHA1.digest(password)).upcase}"
end

