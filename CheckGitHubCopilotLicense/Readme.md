Yes, you can use PowerShell to check GitHub's REST API for your Copilot license status. Here's a basic example of how you might do this:

Generate a Personal Access Token (PAT) with the necessary scopes from your GitHub account settings.

Use the following PowerShell script to make a request to the GitHub API:

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
This script authenticates with the GitHub API using your personal access token and retrieves information about the authenticated user. You can modify the script to check for specific Copilot license information based on the available API endpoints.

Remember to replace "your-username" and "your-personal-access-token" with your actual GitHub username and personal access token. Also, ensure that your token has the necessary scopes to access the information you're trying to retrieve.

For more detailed information on the available API endpoints and the data they return, you can refer to the GitHub API documentation. 😊