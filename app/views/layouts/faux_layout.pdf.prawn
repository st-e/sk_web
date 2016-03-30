pdf = Prawn::Document.new(
	:page_size => 'A4', :page_layout => (@page_layout || :portrait),
	# The page margins are the amount of page not used for the main document
	:left_margin => 1.cm, :right_margin => 1.cm, :top_margin => (2.5).cm, :bottom_margin =>(2.5).cm,
	:compress => true
)

# The header and footer margins are the amount of page not used for the
# header/footer; they are typically smaller than the page margins. The header
# and footer will be printed completely inside these margins.
pdf.header_margin=1.75.cm
pdf.footer_margin=1.5.cm

pdf.header_size=7
pdf.table_size=7

pdf.font_families.update(
	"DejaVuSans" => {
	:bold        => "#{Rails.root}/lib/fonts/DejaVuSans-Bold.ttf",
	:italic      => "#{Rails.root}/lib/fonts/DejaVuSans-Oblique.ttf",
	:bold_italic => "#{Rails.root}/lib/fonts/DejaVuSans-BoldOblique.ttf",
	:normal      => "#{Rails.root}/lib/fonts/DejaVuSans.ttf"
	})


pdf.font "DejaVuSans"
pdf.font_size 7

# Faux yield
render :partial=>@faux_template, :locals=>{:ppdf=>pdf}

pdf.render_headings do |page|
	pdf.    left_header_text pdf.    left_header
	pdf.centered_header_text pdf.centered_header
	pdf.   right_header_text pdf.   right_header

	pdf. left_footer_text "#{Version.instance.version_string}/Prawn #{Version.instance.prawn}"
	pdf.right_footer_text "Seite #{page} von #{pdf.page_count}"
end

