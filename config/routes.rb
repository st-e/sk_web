# encoding: utf-8

ActionController::Routing::Routes.draw do |map|
	# Must be before any entries that will also match :controller=>'home', for
	# example ':controller/:action'
	map.root :controller => 'home', :action=>'index'

	# The priority is based upon order of creation: first created -> highest priority.
	# See how all your routes lay out with "rake routes"

	# Sample of named route:
	#   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
	# This route can be invoked with purchase_url(:id => product.id)

	# Sample resource route with options:
	#   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }



	# Allow POST to edit for the "Select person" subpage
	# Specify the requirements for the ID because periods will confuse routing otherwise
	map.resources :users, :member => { :edit => :post, :change_password => [:get, :post] }, :requirements => { :id => /[a-zA-Z0-9_.-]+/ }
	#map.resources :flights # Not available
	#map.resources :planes # Not available
	map.resources :people, :member => { :overwrite => [:get, :post] }, :collection => { :import => [:get, :post], :export => [:get, :post], :delete_unused => [:post] }


	# Flight list, plane log, pilot log and flight log accept a date specification
	map.flightlist 'flightlist/:date.:format', :controller => 'flightlist', :action => 'show', :requirements => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d)/ }
	map.plane_log  'plane_log/:date.:format' , :controller => 'plane_log' , :action => 'show', :requirements => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d)/ }
	map.pilot_log  'pilot_log/:date.:format' , :controller => 'pilot_log' , :action => 'show', :requirements => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d|\d\d\d\d-\d\d-\d\d_\d\d\d\d-\d\d-\d\d)/ }
	map.flight_db  'flight_db/:date.:format' , :controller => 'flight_db' , :action => 'show', :requirements => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d|\d\d\d\d-\d\d-\d\d_\d\d\d\d-\d\d-\d\d)/ }

	#  map.connect '/usars/:id', :controller => 'users', :action => 'show'


	# Session control
	map.login           'login',  :controller => 'session', :action => 'login'
	map.logout          'logout', :controller => 'session', :action => 'logout'
	map.change_password 'change_password', :controller => 'users', :action => 'change_own_password'

	# Install the default routes as the lowest priority.
	# Note: These default routes make all actions in every controller accessible via GET requests. You should
	# consider removing or commenting them out if you're using named routes and resources.
	# The order is important: more specific first, because for reverse routing, a
	# generic route will also match: users/change_password?id=fred
	# ':controller/:id/:action does not work because it will match
	# session/controller with id='controller' and default action='index'
	#map.connect ':controller/:action/:id' # not used - add members to the resources instead
	map.connect ':controller/:action'
	map.connect ':controller', :action => 'index'
end

