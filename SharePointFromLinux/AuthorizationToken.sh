#!/bin/bash

# Azure OAuth 2.0 credentials
TENANT_ID="48d17adc-2097-4d94-96a9-469cc89d6a5f"
CLIENT_ID="d26641b3-e94d-4119-902b-ae15b3035354"
CLIENT_SECRET="xy48Q~yICtqhjFwtdsOvrZxTTGdJPATZSpbucbQ9"
RESOURCE="https://graph.microsoft.com"
USERNAME="PeterGriffin@ralltheory.com"
PASSWORD="095XANzrBHWwsoALxk3y"

# Get access token
ACCESS_TOKEN=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT_ID/oauth2/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "resource=$RESOURCE" \
    -d "username=$USERNAME" \
    -d "password=$PASSWORD" \
    -d "grant_type=password" | jq -r .access_token)

echo $ACCESS_TOKEN

--------------------------

#!/bin/bash

# Azure OAuth 2.0 credentials
TENANT_ID="48d17adc-2097-4d94-96a9-469cc89d6a5f"
CLIENT_ID="d26641b3-e94d-4119-902b-ae15b3035354"
CLIENT_SECRET="xy48Q~yICtqhjFwtdsOvrZxTTGdJPATZSpbucbQ9"
RESOURCE="https://graph.microsoft.com"

# Get access token
ACCESS_TOKEN=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "scope=$RESOURCE/.default" \
    -d "grant_type=client_credentials" | jq -r .access_token)

echo $ACCESS_TOKEN

