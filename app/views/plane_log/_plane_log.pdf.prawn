ppdf.centered_header="Bordbücher #{Rails.configuration.location}"
render :partial=>'partials/date_range', :locals=>{:ppdf=>ppdf, :date_range=>@date_range}

if @plane_log.empty?
	ppdf.text "Keine Einträge"
else
	@plane_log.keys.sort.each { |club|
		club_text=(club unless club.blank?) || "(Kein Verein)"

		ppdf.section club_text, :size => 10, :style => :bold do
			ppdf.render_table @tables[club]
		end
	}
end

