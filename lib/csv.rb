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

# TODO use the Ruby CSV methods:
# require 'csv'; CSV.open('data.csv', 'r', ';') do |row| p row; end
# Or use faster_csv, ccsv, csvscan, excelsior

# TODO make test methods, csv_escape and csv_unescape must be inverse
def csv_unescape(value)
	return nil if !value

	# OpenOffice rules, again
	# Remove enclosing double quotes
	value=value[1...-1] if value =~ /^".*"$/
	
	# Replace doubled double quote at beginning and end by single double quote
	value.gsub(/^""/, '"').gsub(/""$/, '"')
end

