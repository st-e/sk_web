# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_sk_web_session',
  :secret      => '3509ff50961f3f381a82c3c4ebcdd2b36e00b603da575cde1678e2c77ca3f637f69cd01f0f3cd5687ca952af669452a28f9646167a8e55fc2e63f467660201f8'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
