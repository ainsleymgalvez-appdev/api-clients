require "open-uri"
require "json"

line_width = 40

puts "="*line_width
puts "Will you need an umbrella today?".center(line_width)
puts "="*line_width
puts
puts "Where are you?"
# user_location = gets.chomp
user_location = "The White house"
puts "Checking the weather at #{user_location}...."

# Get the lat/lng of location from Google Maps API


require "./gmaps_wrapper.rb"

x = GmapsWrapper.address_to_coords(user_location)

p x

latitude = x.fetch("lat")

longitude = x.fetch("lng")

# gmaps_key = "AIzaSyAgRzRHJZf-uoevSnYDTf08or8QFS_fb3U"

# gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{user_location}&key=#{gmaps_key}"

# # p "Getting coordinates from:"
# # p gmaps_url

# raw_gmaps_data = URI.open(gmaps_url).read

# parsed_gmaps_data = JSON.parse(raw_gmaps_data)

# results_array = parsed_gmaps_data.fetch("results")

# first_result_hash = results_array.at(0)

# geometry_hash = first_result_hash.fetch("geometry")

# location_hash = geometry_hash.fetch("location")



puts "Your coordinates are #{latitude}, #{longitude}."

# Get the weather from Dark Sky API

dark_sky_key = "26f63e92c5006b5c493906e7953da893"

dark_sky_url = "https://api.darksky.net/forecast/#{dark_sky_key}/#{latitude},#{longitude}"

# p "Getting weather from:"
# p dark_sky_url

raw_dark_sky_data = URI.open(dark_sky_url).read

parsed_dark_sky_data = JSON.parse(raw_dark_sky_data)

currently_hash = parsed_dark_sky_data.fetch("currently")

current_temp = currently_hash.fetch("temperature")

puts "It is currently #{current_temp}°F."

# Some locations around the world do not come with minutely data.
minutely_hash = parsed_dark_sky_data.fetch("minutely", false)

if minutely_hash
  next_hour_summary = minutely_hash.fetch("summary")

  puts "Next hour: #{next_hour_summary}"
end

hourly_hash = parsed_dark_sky_data.fetch("hourly")

hourly_data_array = hourly_hash.fetch("data")

next_twelve_hours = hourly_data_array[1..12]

precip_prob_threshold = 0.10

any_precipitation = false

next_twelve_hours.each do |hour_hash|

  precip_prob = hour_hash.fetch("precipProbability")

  if precip_prob > precip_prob_threshold
    any_precipitation = true

    precip_time = Time.at(hour_hash.fetch("time"))

    seconds_from_now = precip_time - Time.now

    hours_from_now = seconds_from_now / 60 / 60

    puts "In #{hours_from_now.round} hours, there is a #{(precip_prob * 100).round}% chance of precipitation."
  end
end

# TWILIO 
require "twilio-ruby"

twilio_sid = ENV.fetch("TWILIO_ACCOUNT_SID", false)

twilio_token = ENV.fetch("TWILIO_TOKEN", false)

twilio_client = Twilio::REST::Client.new(twilio_sid, twilio_token)

# MAILGUN

require "mailgun-ruby"

mg_api_key = ENV.fetch("MAILGUN_API_KEY")
mg_sending_domain = ENV.fetch("MAILGUN_SENDING_DOMAIN")

mg_client = Mailgun::Client.new(mg_api_key)

if any_precipitation == true
  puts "You might want to take an umbrella!"

    # SENDS TEXT
  sms_info = {
    :from => ENV.fetch("TWILIO_SENDING_PHONE_NUMBER"),
    :to => ENV.fetch("TWILIO_SEND_TO_PHONE_NUMBER"),
    :body => "It's going to rain today - take an umbrella!"
  }

  twilio_client.api.account.messages.create(sms_info)

  # SENDS EMAIL
  email_info = {
    :from => ENV.fetch("SEND_FROM_EMAIL"),
    :to => ENV.fetch("SEND_TO_EMAIL"),
    :subject => "Take an umbrella today!",
    :text => "It's going to rain today, take an umbrella"
  }

  mg_client.send_message(mg_sending_domain, email_info)

  # DOWNLOADED TWILIO AND MAILGUN THROUGH
  # gem install twilio(mailgun)-ruby

else
  puts "You probably won't need an umbrella."
end
