<#
.SYNOPSIS
This script retrieves license assignments for Azure users and sends an email with the license assignments as a CSV attachment.

.DESCRIPTION
The script connects to the Microsoft Graph API to retrieve license information for Azure users. It then maps the SKU IDs to friendly names using a CSV file downloaded from a specified URL. The script retrieves the assigned licenses for each user and determines whether the assignment was made directly or through a group. The script saves the license assignments as a CSV file and converts it to JSON format. It then sends the JSON data to a Log Analytics workspace for logging purposes. Finally, the script sends an email with the license assignments as a CSV attachment.

.PARAMETER None

.EXAMPLE
.\LicensewithGroupsAssignments.ps1
Runs the script to retrieve license assignments and send an email with the license assignments as a CSV attachment.

.NOTES
- This script requires the AzureADPreview module to be installed.
- The script requires the user to have appropriate permissions to access the Microsoft Graph API and send emails.
#>

Write-Output "Connecting to Microsoft Graph..."
# Connect to Microsoft Graph
Connect-MgGraph -Identity

Write-Output "Defining a function to get SKU mappings..."
# Define a function to get SKU mappings
function Get-SkuMappings {
    $skus = Get-MgSubscribedSku
    $skuMapping = @{}
    foreach ($sku in $skus) {
        $skuMapping[$sku.SkuId] = $sku.SkuPartNumber
    }
    return $skuMapping
}

Write-Output "Getting the SKU mappings..."
# Get the SKU mappings
$skuMapping = Get-SkuMappings

Write-Output "Downloading the license table..."
# Create a hash table of the license names
$licenseTableURL = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
# We download the file as a string, convert it to CSV, and select the needed properties
$licenseTable = (Invoke-WebRequest -Uri $licenseTableURL).ToString() | ConvertFrom-Csv | Select-Object Service_Plans_Included_Friendly_Names, GUID, ???Product_Display_Name
$licenseTableHash = @{}
$licenseTable | foreach { $licenseTableHash[$_.GUID] = $_.'???Product_Display_Name' }

Write-Output "Getting all licensed users..."
# Get all licensed users
$users = Get-MgUser -Filter 'assignedLicenses/$count ne 0' -ConsistencyLevel eventual -CountVariable licensedUserCount -All `
-Property AssignedLicenses,LicenseAssignmentStates,UserPrincipalName,DisplayName,AssignedLicenses,UsageLocation,Department,Mail,CompanyName,AccountEnabled,userType,onPremisesSyncEnabled,Id `
| Select-Object UserPrincipalName,DisplayName,AssignedLicenses,UsageLocation,Department,Mail,CompanyName,AccountEnabled,userType,onPremisesSyncEnabled,Id -ExpandProperty LicenseAssignmentStates `
| Select-Object UserPrincipalName, DisplayName, AssignedByGroup, Error, SkuId, Id

Write-Output "Initializing an empty array to store license assignments..."
# Initialize an empty array to store license assignments
$licenseAssignments = @()

Write-Output "Getting all groups that have assigned licenses..."
# Get all groups that have assigned licenses
$licenseGroups = Get-MgGroup -Filter "assignedLicenses/any()" -Select *

Write-Output "Looping through each user and getting their assigned licenses..."
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

Write-Output "Converting the array to CSV format..."
# Convert the array to a CSV format
$csvContent = $licenseAssignments | ConvertTo-Csv -NoTypeInformation

Write-Output "Converting the CSV content to JSON..."
# Convert the CSV content to JSON
$jsonContent = $csvContent | ConvertFrom-Csv | ConvertTo-Json

Write-Output "Defining the Log Analytics Workspace ID and Key..."
# Define the Log Analytics Workspace ID and Key
$workspaceId = "#TODO"
$sharedKey = "#TODO"

Write-Output "Defining the Log Analytics Data Collector API endpoint..."
# Define the Log Analytics Data Collector API endpoint
$logAnalyticsApiEndpoint = "https://$workspaceId.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"

Write-Output "Getting the current date and time..."
# Get the current date and time
$localTime = Get-Date

Write-Output "Converting the local time to UTC..."
# Convert the local time to UTC
$utcTime = $localTime.ToUniversalTime()

Write-Output "Formatting the UTC time in RFC1123 pattern..."
# Format the UTC time in RFC1123 pattern
$date = Get-Date $utcTime -Format r

Write-Output "Creating the signature for the API request..."
# Create the signature for the API request
$stringToHash = "POST`n" + $jsonContent.Length + "`napplication/json`n" + "x-ms-date:" + $date + "`n/api/logs"
$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
$keyBytes = [Convert]::FromBase64String($sharedKey)
$sha256 = New-Object System.Security.Cryptography.HMACSHA256
$sha256.Key = $keyBytes
$calculatedHash = $sha256.ComputeHash($bytesToHash)
$encodedHash = [Convert]::ToBase64String($calculatedHash)
$authorization = 'SharedKey {0}:{1}' -f $workspaceId,$encodedHash

Write-Output "Creating the headers for the API request..."
# Create the headers for the API request
$headers = @{
    "Authorization" = $authorization
    "Log-Type" = "LicenseAssignments"
    "x-ms-date" = $date
    "time-generated-field" = "Date"
}

Write-Output "Sending the data to Log Analytics..."
# Send the data to Log Analytics
#TODO Invoke-WebRequest -Method POST -Uri $logAnalyticsApiEndpoint -ContentType "application/json" -Headers $headers -Body $jsonContent

Write-Output "Defining the email parameters..."
# Define the email parameters
$from = "admin@ralltheory.onmicrosoft.com"   # Replace with your email address
$to = "admin@ralltheory.onmicrosoft.com"     # Replace with your email address
$subject = "Azure License Assignments"
$body = "Please find the attached CSV file with the Azure license assignments."

# Convert CSV content to a base64 string
$csvContentBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csvContent))

$emailMessage = @{
    message = @{
        subject = $subject
        body = @{
            contentType = "Text"
            content = $body
        }
        toRecipients = @(
            @{
                emailAddress = @{
                    address = $to
                }
            }
        )
        attachments = @(
            @{
                '@odata.type' = "#microsoft.graph.fileAttachment"
                name = "licenseAssignments.csv"
                contentBytes = $csvContentBase64
            }
        )
    }
    saveToSentItems = $true
}

# Convert the PowerShell object to JSON
$emailMessageJson = $emailMessage | ConvertTo-Json -Depth 10

Write-Output "Sending the email..."
# Send the email
Send-MgUserMail -UserId $from -BodyParameter $emailMessageJson


Write-Output "Email sent successfully with the license assignments."
