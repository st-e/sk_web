# encoding: utf-8

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


