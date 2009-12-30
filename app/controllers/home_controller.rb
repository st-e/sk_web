class HomeController < ApplicationController
	allow_public :only => [:index]

	def index
		render
	end
end

