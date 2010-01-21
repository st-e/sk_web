first=date_range.begin
last=date_range.end
last=last-1 if date_range.exclude_end?

if first==last
	ppdf.right_header date_formatter(german_format, true).call(first)
else
	ppdf.right_header "#{date_formatter(german_format, true).call(first)} bis #{date_formatter(german_format, true).call(date_range.end)}"
end
