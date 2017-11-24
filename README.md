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

### Registration for Twilio Authenticator SDK version 2

```
POST /v2/[prod|stg]/registration
params:
- user_id, required
- apps[], array of app_ids. *If omitted the registration_token will indicate all apps in the `api_keys.yml` file for the given environment and version.*
`POST /v2/stg/registration?user_id=12345`
```
returns:
```
{
  registration_token: jwt
}
```
*Note: jwt is signed with the integration_api_key*

