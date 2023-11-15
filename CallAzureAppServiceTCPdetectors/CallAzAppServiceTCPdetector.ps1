# Import the required module
Import-Module Az.Accounts

# Login to your Azure account
$azureAccount = Connect-AzAccount

# Get the access token
$accessToken = (Get-AzAccessToken -ResourceUrl https://management.azure.com/).Token

# Define the URL for the API call
$url = "https://management.azure.com/subscriptions/#TODO/resourcegroups/#TODO/providers/microsoft.web/sites/#TODO/detectors/LinuxTcpStates?startTime=2023-10-30%2014:05&endTime=2023-10-31%2013:49&api-version=2015-08-01"

# Make the API call
$response = Invoke-RestMethod -Uri $url -Headers @{Authorization="Bearer $accessToken"} -Method Get

# Print the response
$response.properties

# Get the dataset property
$dataset = $response.properties.dataset

# Convert the dataset object to a JSON string
$jsonString = $dataset | ConvertTo-Json

# Print the JSON string
$jsonString