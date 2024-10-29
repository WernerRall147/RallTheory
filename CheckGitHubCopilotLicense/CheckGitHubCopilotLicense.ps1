# Replace with your GitHub username and personal access token
$username = "your-username"
$token = "your-personal-access-token"

# GitHub API endpoint to get the authenticated user's information
$url = "https://api.github.com/user"

# Create a headers object with the authorization token
$headers = @{
    Authorization = "Bearer $token"
    "User-Agent" = "PowerShell"
}

# Make the API request
$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

# Output the response
$response