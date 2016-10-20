# encoding: utf-8

class NilClass
	def to_b
		false
	end

	def strip
		self
	end
end

