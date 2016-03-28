# encoding: utf-8

class DebugController < ApplicationController
	allow_public :dump_environment, :delay

	def dump_environment
	end

	def delay
		sleep 10
		render :text=>"OK"
	end
end

