require 'bundler/setup'
require 'json'
require 'net/http'
require 'jwt'

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

  def build_registration_token(authy_id, app_id, hmac_secret, account_sid)

      payload = {:jti => '#{app_id}-#{Time.now.to_i}', :iss =>  app_id, :sub => account_sid, :nbf => Time.now.to_i - 60, :exp => Time.now.to_i + 10*3600,
        :grants => {
          :identity => "",
          :authenticator => {
            :authy_id => authy_id
          }
      }}

      token = JWT.encode payload, hmac_secret, 'HS256'
  end

end

get "/" do
  content_type :text

  DOCUMENTATION
end

post "/registration" do
  param :authy_id, Integer, required: true

  integration_api_key = ENV["AUTHY_INTEGRATION_API_KEY"]
  token = build_registration_token(params[:authy_id], ENV["APP_ID"], integration_api_key, ENV["ACCOUNT_SID"])

  respond_with status: 200, body: {registration_token: token, integration_api_key: integration_api_key}

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

