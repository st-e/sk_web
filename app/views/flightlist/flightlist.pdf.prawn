pdf = Prawn::Document.new(
	:page_size => 'A4', :page_layout => :landscape,
	:skip_page_creation => true,
	:left_margin => 1.cm, :right_margin => 1.cm, :top_margin => (2.5).cm, :bottom_margin =>(2.5).cm
)

pdf.header_margin=1.75.cm
pdf.footer_margin=1.5.cm
pdf.header_size=7
pdf.table_size=7

#pdf.on_page_create do
#	pdf.font "DejaVuSans.ttf"
#	pdf.font_size font_size
#end

pdf.start_new_page

pdf.font "#{Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"
pdf.font_size 7

##############################################################
# This is the actual content, the rest should be in the layout
##############################################################
pdf.text "#{@flights.size} Flüge"
pdf.paragraph
pdf.render_table @table
##############################################################


pdf.render_headings do |page|
	pdf.centered_header "Hauptflugbuch Dingenskirchen"
	#pdf.right_header "x.xx.xxxx"
	render :partial=>'partials/date_range', :locals=>{:ppdf=>pdf, :date_range=>@date_range}

	pdf.left_footer "#{version_string}/Prawn #{Prawn::VERSION}"
	pdf.right_footer "Seite #{page} von #{pdf.page_count}"
end

