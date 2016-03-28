# encoding: utf-8

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
		.gsub('-', '{-}') \
		.gsub(',', '{,}') \
		.gsub('`', '{`}') \
		.gsub("'", "{'}")
	# [-,`'] can have special meanings (---, ,,, ``, '')
	# Seems like guilsingl{left,right} don't work properly
	# .gsub('<', '\\guilsinglleft{}')
	# .gsub('>', '\\guilsinglright{}')
end

alias_method :l, :latex_escape

