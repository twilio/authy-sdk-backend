# Authy SDK Backend

The following project is a sample for implementing the backend needed for supporting the Authy SDK.

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/authy/authy-sdk-backend)

Usage:

### Phone Verification
```
POST /verify/token
params:
phone_number, required
```
returns:
```
{
  jwt_token: jwt_token
}
```
*Note: jwt_token is signed with ENV[AUTHY_API_KEY]*

### Registration for Twilio Authenticator SDK version 1
```
POST /v1/[prod|stg]/app_id/registration
params:
authy_id, required
```
returns:
```
{
  registration_token: token
}
```

#### Backend implementation for version 1
In order to get an authy_id you must register the user through this call:
POST https://<AUTHY_API_URL>/protected/json/sdk/registrations

  params:
    api_key="Your AUTHY_API_KEY"
    user[email]=USER_EMAIL String (required)
    user[cellphone]=USER_PHONE_NUMBER String (required)
    user[country_code]=PHONE_COUNTRY_CODE String (required)

### Registration for Twilio Authenticator SDK version 2

```
POST /v2/[prod|stg]/registration
params:
- user_id, required
- app_ids[], array of app_ids. *If omitted the registration_token will indicate all apps in the `api_keys.yml` file for the given environment and version.*

POST /v2/stg/registration
form params:
- user_id: "12345"
- app_ids[]: app_1
- app_ids[]: app_2
```
returns:
```
{
  registration_token: jwt
}
```
*Note: jwt is signed with the integration_api_key*



