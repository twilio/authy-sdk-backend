require 'bundler/setup'

Bundler.require

if File.exist?("env.rb")
  load "./env.rb"
end

ENV["AUTHY_API_URL"] ||= "https://api.authy.com"

StatusOK     = 200
StatusFailed = 400

DOCUMENTATION = %@To start the registration process call:

    POST /registration/start
    params:
      country_code=<phone country code, ex: 1>
      phone_number=<user's phone number>
      email=<user's email>
      via=sms

This will send a pin to the user, then you have to capture it in your app and call:

    POST /registration/complete
    params:
      country_code=<phone country code, ex: 1>
      phone_number=<user's phone number>
      pin=<pin>

If the <pin> is valid this end point will return a registration token that you need to pass to the SDK to complete the registration process.
@

helpers do
  def respond_with(status:, body: {})
    halt status, {'Content-Type' => 'application/json'}, body.to_json
  end

  def build_url(path)
    "#{ENV["AUTHY_API_URL"]}#{path}"
  end

  def build_params_for_authy(*params_to_copy)
    new_params = {
      api_key: ENV["AUTHY_API_KEY"]
    }
    params_to_copy.each do |param_name|
      new_params[param_name] = params[param_name]
    end
    new_params
  end
end

get "/" do
  content_type :text

  DOCUMENTATION
end

post "/registration/start" do
  param :country_code, Integer, required: true
  param :phone_number, String, required: true
  param :email, String, required: true
  param :via, String, required: true, in: ["sms", "call"]

  params_for_authy = build_params_for_authy(:country_code, :phone_number, :email, :via)

  response = RestClient.post(build_url("/protected/json/registrations/start"), params_for_authy)

  if response.code == 200
    respond_with status: StatusOK
  end

  respond_with status: StatusFailed
end

post "/registration/complete" do
  param :country_code, Integer, required: true
  param :phone_number, String, required: true
  param :pin, String, required: true

  params_for_authy = build_params_for_authy(:country_code, :phone_number, :pin)

  response = RestClient.post(build_url("/protected/json/registrations/confirm"), params_for_authy)

  if response.code == 200
    authy_response = JSON.parse(response.body)
    respond_with status: StatusOK, body: {registration_token: authy_response["registration_token"]}
  end

  respond_with status: StatusFailed
end

