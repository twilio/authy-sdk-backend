require 'bundler/setup'

Bundler.require

if File.exist?("env.rb")
  load "./env.rb"
end

ENV["AUTHY_API_URL"] ||= "https://api.authy.com"

StatusOK     = 200
StatusFailed = 400

DOCUMENTATION = %@To start the registration process call:

    POST /registration
    params:
      authy_id<user's authy id>

This will return a registration token that you need to pass to the SDK to complete the registration process.
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

post "/registration" do
  param :authy_id, Integer, required: true

  params_for_authy = build_params_for_authy(:authy_id)

  response = RestClient.post(build_url("/protected/json/sdk/registrations"), params_for_authy)

  if response.code == 200
    authy_response = JSON.parse(response.body)
    respond_with status: StatusOK, body: {registration_token: authy_response["registration_token"]}
  end

  respond_with status: StatusFailed
end

