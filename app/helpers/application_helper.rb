require 'util'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	def latex_escape(value)
		return nil if !value
		
		# This is a bit ugly because \ gets \textbackslash{}, and { gets \{
		# (likewise, } gets \}), so each of these would escape the
		# already-escaped other. Thus, we only replace \ if not followed by {
		# or } (that is, either a different character or the end of the line).
		# Also, \, { and } are replaced first because they also occur in many
		# other subsitutions
		value.to_s \
			.gsub('{', '\\{') \
			.gsub('}', '\\}') \
			.gsub(/\\([^{}])/, '\\textbackslash{}\\1') \
			.gsub(/\\$/, '\\textbackslash{}') \
			.gsub('$', '\\$') \
			.gsub('%', '\\%') \
			.gsub('_', '\\_') \
			.gsub('&', '\\&') \
			.gsub('#', '\\#') \
			.gsub('^', '\\textasciicircum{}') \
			.gsub('~', '\\textasciitilde{}') \
			.gsub('"', '\\textquotedbl{}') \
			.gsub('-', '{-}') # - can have a special meaning, for example in ---
			# Seems like guilsingl{left,right} don't work properly
			# .gsub('<', '\\guilsinglleft{}')
			# .gsub('>', '\\guilsinglright{}')

			# TODO: " shoud be ,,/``
			# TODO: , and ` must be escaped (because of ,, and ``; what about ''?)
	end

	alias_method :l, :latex_escape

	def csv_escape(value)
		# Rules for OpenOffice:
		#   - enclosing double quotes are removed
		#   - after that, doubled double quotes at the beginning and at the end
		#     (not in the middle) are replaced by a single double quote
		# TODO determine rules for MS Excel

		return nil if !value

		value=value.to_s

		# Replace double quotes at the beginning or at the end with two double quotes
		# Don't use gsub! becaus that will change the original string
		value=value \
			.gsub(/^"/, '""') \
			.gsub(/"$/, '""')

		# If the value contains a comma or begins or ends with a double quote,
		# enclose it in double quotes
		value="\"#{value}\"" if (value =~ /,/ || value =~ /^"/ || value =~ /"$/)

		value
	end

	alias_method :c, :csv_escape

	def version_string
		ruby="Ruby #{RUBY_VERSION}"
		rails="Rails #{Rails::VERSION::STRING}"
		mysql="MySQL #{Mysql.client_version.to_s.sub(/^(.)(..)(..)/, '\\1.\\2.\\3')}"
		"sk_web Version 2.0 (experimental)/#{ruby}/#{rails}/#{mysql}"
		# RUBY_RELEASE_DATE
	end

	def page_title(title)
		content_for :title do
			title
		end
		"<h1>#{title}</h1>"
	end
end

