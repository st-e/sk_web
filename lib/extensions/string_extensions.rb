# encoding: utf-8

class String
	def to_b
		if match(/^(true|t|yes|y|1|-1)$/i) != nil
			true
		elsif match(/^(false|f|no|n|0)$/i) != nil
			false
		else
			nil
		end
	end
end


