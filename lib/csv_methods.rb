# encoding: utf-8

def make_csv
	out=CSV::generate { |csv|
		yield csv
	}

	out
end

