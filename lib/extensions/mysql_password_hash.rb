# encoding: utf-8

require 'digest/sha1'

def mysql_password_hash(password)
	"*#{Digest::SHA1.hexdigest(Digest::SHA1.digest(password)).upcase}"
end

