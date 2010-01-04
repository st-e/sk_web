ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes"

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }



  map.resources :users, :member => { :change_password => :get }
  map.resources :flights
  map.resources :planes
  map.resources :people
  
  map.flightlist 'flightlist/:date.:format', :controller => 'flightlist', :action => 'show', :requirements => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d)/ }
  map.plane_log  'plane_log/:date.:format' , :controller => 'plane_log' , :action => 'show', :requirements => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d)/ }
  map.pilot_log  'pilot_log/:date.:format' , :controller => 'pilot_log' , :action => 'show', :requirements => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d)/ } # TODO or range
  map.flight_db  'flight_db/:date.:format' , :controller => 'flight_db' , :action => 'show', :requirements => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d)/ } # TODO or range

  map.login  'login',  :controller => 'session', :action => 'login'
  map.logout 'logout', :controller => 'session', :action => 'logout'


  # The order is important: more specific first, because for reverse routing, a
  # generic route will also match: users/change_password?id=fred
  # ':controller/:id/:action does not work because it will match
  # session/controller with id='controller' and default action='index'

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  #map.connect ':controller/:action/:id' # not used - add members to the resources instead
  map.connect ':controller/:action'
  map.connect ':controller', :action => 'index'

  map.root :controller => 'home'
end

