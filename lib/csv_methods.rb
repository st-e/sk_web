def make_csv
	out=""

	CSV::Writer.generate(out) { |csv|
		yield csv
	}

	out
end

