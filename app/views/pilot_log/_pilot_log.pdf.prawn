ppdf.centered_header="Flugbuch für #{@person.full_name}"
render :partial=>'partials/date_range', :locals=>{:ppdf=>ppdf, :date_range=>@date_range}

render :partial=>'partials/flight_count', :locals=>{:ppdf=>ppdf, :num_flights=>@flights.size}
ppdf.paragraph
ppdf.render_table @table unless @flights.empty?

