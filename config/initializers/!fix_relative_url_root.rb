# automatic relative_url_root fix
# Improved from http://ptspts.blogspot.com/2009/05/how-to-fix-railsbaseuri-sub-uri-with.html
fail unless ActionController::Request       # check loaded
module ActionController
	class Request
		alias :initialize__fix_relative_url_root :initialize

		def initialize(env)
			# Call the original initialize method
			initialize__fix_relative_url_root(env)
			#@env=env  # Rack::Request#initialize does only this

			# Determine the script name from the environment
			script_name=env['SCRIPT_NAME']
			puts "script_name is #{script_name}"

			# We rewrite into public/. Also, there may be duplicate slashes.
			if !script_name.blank? && script_name =~ /(.*)\/+public\/+dispatch\.(fcgi|fb|cgi)/
				rur=$1
				puts "Setting relative_url_root to #{rur}"
				Base.relative_url_root=rur
			end
		end
	end
end

