require 'test_helper'

#require 'util'

class TextTest < ActiveSupport::TestCase
	test "mysql_password_hash" do
		assert_equal "*8C7857D7204579DF6739D947D15E4E64D689CF15", mysql_password_hash('moobert')
	end
end

