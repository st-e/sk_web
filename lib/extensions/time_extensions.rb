# encoding: utf-8

require 'date'

class Time
	def date
		Date.new(year, month, day)
	end
end

