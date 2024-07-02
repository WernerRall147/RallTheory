# Install and import necessary modules
Install-Module -Name Az -AllowClobber -Force
Import-Module Az

# Connect to Azure account
Connect-AzAccount

# Define the Azure Resource Graph query
$query = @"
resources
| where (type == "microsoft.hybridcompute/machines/extensions" or type == "microsoft.compute/virtualmachines/extensions")
    and properties.provisioningState != "Succeeded"
| extend 
    VMId = toupper(substring(id, 0, indexof(id, "/extensions"))),
    ExtensionName = tostring(properties.type),
    Provisioned = tostring(properties.provisioningState)
| join kind=leftouter (
    resources
    | where type == "microsoft.hybridcompute/machines" or type == "microsoft.compute/virtualmachines"
    | extend
        JoinID = toupper(id),
        OSName = tostring(name),
        SubId = tostring(subscriptionId),
        RSG = tostring(resourceGroup),
        LOC = tostring(location),
        OSType = tostring(properties.storageProfile.osDisk.osType)
) on $left.VMId == $right.JoinID
| summarize Extensions = make_list(ExtensionName), ExtensionStates = make_list(Provisioned) by OSName, SubId, RSG, LOC, OSType
| where array_length(Extensions) > 0
"@

# Run the query and get results
$results = Search-AzGraph -Query $query -First 1000

# Convert results to a PowerShell object
$affectedVMs = $results | ConvertFrom-Json
