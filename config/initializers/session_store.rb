# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.

# Create a session secret if it does not already exist in
# config/session_secret.txt

config_dir=File.join(RAILS_ROOT, "config")
config_dir=File.join(ENV['SK_WEB_ETC']) if ENV['SK_WEB_ETC'] # Probably /etc/startkladde

secret_file=File.join(config_dir, "session_secret.txt")
if File.exist?(secret_file)
	# The secret file exists - read the secret from the file
	secret=File.open(secret_file, 'r') { |file| file.readline.strip }
else
	# The secret file does not exist - generate a secret and write it to the
	# file
	secret=ActiveSupport::SecureRandom.hex(64)
	File.open(secret_file, 'w', 0600) { |file| file.write(secret) }
end

ActionController::Base.session = {
  :key         => '_sk_web_session',
  :secret      => secret #'3509ff50961f3f381a82c3c4ebcdd2b36e00b603da575cde1678e2c77ca3f637f69cd01f0f3cd5687ca952af669452a28f9646167a8e55fc2e63f467660201f8'
#  :expire_after => 2.minutes
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
