require 'bundler/setup'
require 'json'
require 'net/http'

Bundler.require

if File.exist?("env.rb")
  load "./env.rb"
end

ENV["AUTHY_API_URL"] ||= "https://api.authy.com"

DOCUMENTATION = %@To start the registration process call:

    POST /registration
    params:
      authy_id <user's authy id>

This will return a registration token that you need to pass to the SDK to complete the registration process.


NOTE
----
In order to get an authy_id you must register the user through this call:
POST #{ENV["AUTHY_API_URL"]}/protected/json/sdk/registrations
  params:
    api_key="Your AUTHY_API_KEY"
    user[email]=USER_EMAIL String (required)
    user[cellphone]=USER_PHONE_NUMBER String (required)
    user[country_code]=PHONE_COUNTRY_CODE String (required)
@

helpers do
  def respond_with(status:, body: {})
    halt status, {'Content-Type' => 'application/json'}, body.to_json
  end

  def build_url(path)
    "#{ENV["AUTHY_API_URL"]}#{path}"
  end

  def build_params_for_authy(authy_id)
    {
      api_key: ENV["AUTHY_API_KEY"],
      authy_id: authy_id
    }
  end
end

get "/" do
  content_type :text

  DOCUMENTATION
end

post "/registration" do
  param :authy_id, Integer, required: true

  params_for_authy = build_params_for_authy(params[:authy_id])

  response = Net::HTTP.post_form(URI.parse(build_url("/protected/json/sdk/registrations")), params_for_authy)
  response_code = response.code.to_i

  parsed_response = JSON.parse(response.body)

  if response_code == 200
    respond_with status: response_code, body: {registration_token: parsed_response["registration_token"] }

  else
    respond_with status: response_code, body: parsed_response

  end
end

post "/verify/token" do
  param :phone_number, String, required: true

  payload = {
    app_id: ENV["APP_ID"],
    phone_number: params[:phone_number],
    iat: Time.now.to_i
  }

  jwt_token = JWT.encode(payload, ENV["AUTHY_API_KEY"], "HS256")

  respond_with status: 200, body: {jwt_token: jwt_token}
end

