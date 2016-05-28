# encoding: utf-8

# address is an array of 4 strings
def address_matches(spec, address)
    (0..3).all? { |i| spec[i]=='*' || spec[i]==address[i] }
end

# address is a string
def address_is_local?(address)
    Rails.configuration.local_addresses.any? { |spec| address_matches spec.strip.split('.'), address.strip.split('.') }
end

