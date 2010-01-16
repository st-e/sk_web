module ActionView
	module Helpers
		module FormHelper
			def hidden_field(object_name, method, options = {})
				# Alias doesn't seem to work - copy the contents of the original method
				result=InstanceTag.new(object_name, method, self, options.delete(:object)).to_input_field_tag("hidden", options)
				result+="<span class=\"hidden_field\">[#{h method}=#{h options[:value].inspect}]</span>" if session[:debug]
				result
			end
		end
	end
end


