require 'bundler/setup'
require 'json'
require 'net/http'
require 'yaml'

Bundler.require

if File.exist?("env.rb")
  load "./env.rb"
end

API_KEYS = YAML.load_file('api_keys.yml')

helpers do
  def respond_with(status:, body: {})
    halt status, {'Content-Type' => 'application/json'}, body.to_json
  end

  def build_url(environment, path)
    "#{ENV["AUTHY_API_URL_"+environment.upcase]}#{path}"
  end
end

get "/" do
  content_type :text

  send_file("usage.txt")
end

post "/v1/:environment/:app_id/registration" do |environment, app_id|
  param :authy_id, Integer, required: true

  respond_with status: 404, body: "environment should be [prod|stg]" unless ["prod", "stg"].include? environment

  response = Net::HTTP.post_form(URI.parse(build_url(environment, "/protected/json/sdk/registrations")), {
      api_key: API_KEYS["v1"][environment][app_id],
      authy_id: params[:authy_id]
    })
  response_code = response.code.to_i

  parsed_response = JSON.parse(response.body)

  if response_code == 200
    respond_with status: response_code, body: {registration_token: parsed_response["registration_token"] }

  else
    respond_with status: response_code, body: parsed_response

  end
end

post "/v2/:environment/registration" do |environment|
  param :user_id, Integer, required: true
  param :apps, Array

  # If apps are not indicated, add the user to all of them.
  params[:apps] ||= API_KEYS["v2"][environment]

  respond_with status: 404, body: "environment should be [prod|stg]" unless ["prod", "stg"].include? environment

  environment = environment.upcase

  payload = {
    jti: "123456",
    sub: ENV["ACCOUNT_SID_"+environment],
    nbf: Time.now.to_i,
    exp: (Time.now+5 * 60).to_i,
    grants: {
      authenticator: {
        user_id: params[:user_id],
        apps: params[:apps]
      }
    }
  }
  integration_api_key = ENV["INTEGRATION_API_KEY_"+environment]

  jwt_token = JWT.encode(payload, integration_api_key, "HS256")

  respond_with status: 200, body: { registration_token: jwt_token }
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

