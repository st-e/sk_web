# encoding: utf-8

SkWeb::Application.routes.draw do
    match '/' => 'home#index'
    
    # Allow POST to edit for the "Select person" subpage
    # Specify the requirements for the ID because periods will confuse routing otherwise
    resources :users do
        member do
            post :edit
            get :change_password
            post :change_password
        end
    end

    resources :people do
        collection do
            get :import
            post :import
            get :export
            post :export
            post :delete_unused
        end
        
	member do
            get :overwrite
            post :overwrite
        end
    end

    # Flight list, plane log, pilot log and flight log accept a date specification
    match 'flightlist/:date.:format' => 'flightlist#show', :as => :flightlist, :constraints => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d)/ }
    match 'plane_log/:date.:format' => 'plane_log#show', :as => :plane_log, :constraints => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d)/ }
    match 'pilot_log/:date.:format' => 'pilot_log#show', :as => :pilot_log, :constraints => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d|\d\d\d\d-\d\d-\d\d_\d\d\d\d-\d\d-\d\d)/ }
    match 'flight_db/:date.:format' => 'flight_db#show', :as => :flight_db, :constraints => { :date => /(today|yesterday|\d\d\d\d-\d\d-\d\d|\d\d\d\d-\d\d-\d\d_\d\d\d\d-\d\d-\d\d)/ }
    
    # Session control
    match 'login' => 'session#login', :as => :login
    match 'logout' => 'session#logout', :as => :logout
    match 'change_password' => 'users#change_own_password', :as => :change_password
    match ':controller/:action' => '#index'
    match ':controller' => '#index'
end
