# Import the module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "Mail.Send", "Organization.Read.All"

# Define a function to get SKU mappings
function Get-SkuMappings {
    $skus = Get-MgSubscribedSku
    $skuMapping = @{}
    foreach ($sku in $skus) {
        $skuMapping[$sku.SkuId] = $sku.SkuPartNumber
    }
    return $skuMapping
}

# Get the SKU mappings
$skuMapping = Get-SkuMappings

# Get all users
$users = Get-MgUser -All

# Initialize an empty array to store license assignments
$licenseAssignments = @()

# Loop through each user and get their assigned licenses
foreach ($user in $users) {
    $userLicenses = Get-MgUserLicenseDetail -UserId $user.Id
    foreach ($license in $userLicenses) {
        $friendlyName = $skuMapping[$license.SkuId] # Get the friendly name from the mapping
        $licenseAssignments += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName       = $user.DisplayName
            SkuPartNumber     = $friendlyName
            SkuId             = $license.SkuId
        }
    }
}

# Convert the array to a CSV format
$csvContent = $licenseAssignments | ConvertTo-Csv -NoTypeInformation

# Define the email parameters
$from = "your-email@domain.com"   # Replace with your email address
$to = "your-email@domain.com"     # Replace with your email address
$subject = "Azure License Assignments"
$body = "Please find the attached CSV file with the Azure license assignments."
$attachmentPath = "C:\path\to\licenseAssignments.csv" # Path to save the CSV file

# Save the CSV content to a file
$csvContent | Out-File -FilePath $attachmentPath -Encoding UTF8

# Read the CSV file content
$fileContent = [System.IO.File]::ReadAllBytes($attachmentPath)
$fileBase64 = [System.Convert]::ToBase64String($fileContent)

# Create the email message
$emailMessage = @{
    Message = @{
        Subject = $subject
        Body = @{
            ContentType = "Text"
            Content = $body
        }
        ToRecipients = @(
            @{
                EmailAddress = @{
                    Address = $to
                }
            }
        )
        Attachments = @(
            @{
                '@odata.type' = "#microsoft.graph.fileAttachment"
                Name = "licenseAssignments.csv"
                ContentBytes = $fileBase64
            }
        )
    }
    SaveToSentItems = "true"
}

# Send the email
Send-MgUserMessage -UserId $from -BodyParameter $emailMessage

# Output a message indicating the email has been sent
Write-Output "Email sent successfully with the license assignments."
