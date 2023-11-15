#how to use this
# Next Steps:
# 1. Register an application in Azure Active Directory to get your credentials.
# 2. Use the credentials to authenticate your application and get access tokens.
# 3. Use the access tokens to make authorized requests to the Microsoft Graph API.

# Define your credentials
$clientID = "#TODO"
$clientSecret = "#TODO"
$tenantID = "#TODO"

# Define the resource URL
$resource = "https://graph.microsoft.com"

# Define the token URL
$tokenURL = "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token"

# Define the body for the token request
$body = @{
    client_id     = $clientID
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

# Get the access token
$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenURL -Body $body
$accessToken = $tokenResponse.access_token

# Define the header for the API request
$header = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type'  = "application/json"
}

# Make the API request
$apiURL = "https://graph.microsoft.com/beta/users"
$response = Invoke-RestMethod -Method Get -Uri $apiURL -Headers $header

# Output the response
$gen = $response.value | convertto-csv -NoTypeInformation  
$gen | Out-File -FilePath C:\Temp\AzureEntraUsers.csv