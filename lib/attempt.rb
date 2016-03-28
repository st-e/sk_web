# encoding: utf-8

# You can use redo in a block, like so:
# attempt do
#	@users = User.paginate :page => the_page
#	the_page =1 and redo if @users.out_of_bounds?
# end
def attempt
	yield
end

