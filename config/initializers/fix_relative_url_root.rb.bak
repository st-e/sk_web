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

			script_name=env['SCRIPT_NAME']
			if !script_name.blank?
				# Only if relative_url_root is blank to allow overriding by
				# ENV['RAILS_RELATIVE_URL_ROOT']
				if Base.relative_url_root.blank?
					rur=nil
					# There may be duplicate slashes.
					if script_name =~ /(.*)\/+public\/+sk_web\.(fcgi|rb|cgi)/
						# We rewrite into public/, but public/ is not part of
						# the relative URL root
						rur=$1
					elsif script_name =~ /(.*)\/+sk_web\.(fcgi|rb|cgi)/
						# We don't rewrite into public/
						rur=$1
					end

					STDERR.puts "SCRIPT_NAME is #{script_name}"
					if rur
						STDERR.puts "Setting relative_url_root to #{rur}"
						Base.relative_url_root=rur
					else
						STDERR.puts "Script name not recognized - not setting relative_url_root"
					end
				end
			end

			STDERR.flush
		end
	end
end

