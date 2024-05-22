# Import the module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "Mail.Send", "Group.Read.All"

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

# Create a hash table of the license names
$licenseTableURL = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
# We download the file as a string, convert it to CSV, and select the needed properties
$licenseTable = (Invoke-WebRequest -Uri $licenseTableURL).ToString() | ConvertFrom-Csv | Select-Object Service_Plans_Included_Friendly_Names, GUID, ???Product_Display_Name
$licenseTableHash = @{}
$licenseTable | foreach { $licenseTableHash[$_.GUID] = $_.'???Product_Display_Name' }

# Get all licensed users
$users = Get-MgUser -Filter 'assignedLicenses/$count ne 0' -ConsistencyLevel eventual -CountVariable licensedUserCount -All `
-Property AssignedLicenses,LicenseAssignmentStates,UserPrincipalName,DisplayName,AssignedLicenses,UsageLocation,Department,Mail,CompanyName,AccountEnabled,userType,onPremisesSyncEnabled,Id `
| Select-Object UserPrincipalName,DisplayName,AssignedLicenses,UsageLocation,Department,Mail,CompanyName,AccountEnabled,userType,onPremisesSyncEnabled,Id -ExpandProperty LicenseAssignmentStates `
| Select-Object UserPrincipalName, DisplayName, AssignedByGroup, Error, SkuId, Id

# Initialize an empty array to store license assignments
$licenseAssignments = @()

# Get all groups that have assigned licenses
$licenseGroups = Get-MgGroup -Filter "assignedLicenses/any()" -Select *

# Loop through each user and get their assigned licenses
foreach ($user in $users) {
    $userLicenses = Get-MgUserLicenseDetail -UserId $user.Id
    foreach ($license in $userLicenses) {
        $friendlyName = $licenseTableHash[$license.SkuId] # Get the friendly name from the mapping
        $assignmentType = "Direct"
        $groupId = "N/A"
        $groupName = "N/A"

        if ($null -ne $user.AssignedByGroup) {
            try {
                $groupId = $user.AssignedByGroup
                # Get the group name from the license groups
                $group = $licenseGroups | Where-Object { $_.Id -eq $groupId }
                if ($null -ne $group) {
                    $groupName = $group.DisplayName
                }
                $assignmentType = "Group"
            } catch {
                Write-Warning "Could not retrieve group details for group ID: $groupId"
            }
        }

        $licenseAssignments += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName       = $user.DisplayName
            SkuPartNumber     = $friendlyName
            SkuId             = $license.SkuId
            AssignmentType    = $assignmentType
            GroupId           = $groupId
            GroupName         = $groupName
        }
    }
}

# Convert the array to a CSV format
$csvContent = $licenseAssignments | ConvertTo-Csv -NoTypeInformation

# Define the email parameters
$from = "#TODO your-email@domain.com"   # Replace with your email address
$to = "#TODO your-email@domain.com"     # Replace with your email address
$subject = "Azure License Assignments"
$body = "Please find the attached CSV file with the Azure license assignments."
$attachmentPath = "#TODO C:\path\to\licenseAssignments.csv" # Path to save the CSV file

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
Send-MgUserMail -UserId $from -BodyParameter $emailMessage

# Output a message indicating the email has been sent
Write-Output "Email sent successfully with the license assignments."
