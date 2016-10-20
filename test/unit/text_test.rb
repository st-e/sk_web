require 'test_helper'

#require 'text'

class TextTest < ActiveSupport::TestCase
	test "to_b" do
		assert "true".to_b
		assert "t".to_b
		assert "yes".to_b
		assert "y".to_b
		assert "1".to_b

		assert !("false".to_b)
		assert !("f".to_b)
		assert !("no".to_b)
		assert !("n".to_b)
		assert !("0".to_b)

		assert !("".to_b)
	end

	test "format_duration" do
		assert_equal   "0:00:01", format_duration(     1, true)
		assert_equal   "0:00:10", format_duration(    10, true)
		assert_equal   "0:01:00", format_duration(    60, true)
		assert_equal   "0:01:02", format_duration(    62, true)
		assert_equal   "0:04:16", format_duration(   256, true)
		assert_equal   "1:00:01", format_duration(  3601, true)
		assert_equal  "10:01:03", format_duration( 36063, true)
		assert_equal "100:00:00", format_duration(360000, true)

		assert_equal   "0:00", format_duration(     1, false)
		assert_equal   "0:00", format_duration(    10, false)
		assert_equal   "0:01", format_duration(    60, false)
		assert_equal   "0:01", format_duration(    62, false)
		assert_equal   "0:04", format_duration(   256, false)
		assert_equal   "1:00", format_duration(  3601, false)
		assert_equal  "10:01", format_duration( 36063, false)
		assert_equal "100:00", format_duration(360000, false)
	end
end

