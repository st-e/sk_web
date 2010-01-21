def version_string
	ruby="Ruby #{RUBY_VERSION}"
	rails="Rails #{Rails::VERSION::STRING}"
	mysql="MySQL #{Mysql.client_version.to_s.sub(/^(.)(..)(..)/, '\\1.\\2.\\3')}"
	"sk_web Version 2.0 (experimental)/#{ruby}/#{rails}/#{mysql}"
	# RUBY_RELEASE_DATE
end


