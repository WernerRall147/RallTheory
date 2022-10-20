$machineslist = 

#find the Machines with AMA Installed
$MMASearch = Search-AzGraph -Query '
Resources
| where type == "microsoft.compute/virtualmachines"
| extend osType = tostring(properties.storageProfile.osDisk.osType)
| extend powerState = tostring(properties.extended.instanceView.powerState.displayStatus)
| where powerState == "VM running"
| where osType == "Windows"
| project
    id,
    JoinID = toupper(id),
    OSName = tostring(properties.osName),
    status = tostring(properties.status),
    machineName = name,
    osType,
    location,
    powerState
| join kind=leftouter(
    Resources
    | where type == "microsoft.compute/virtualmachines/extensions"
//    | where resourceGroup =~ "{vResourceGroup}"
    | project
        MachineId = toupper(substring(id, 0, indexof(id, "/extensions"))),
        ExtensionName = name
) on $left.JoinID == $right.MachineId
| summarize Extensions = make_list(ExtensionName) by id, OSName, status, machineName, osType, location, powerState
| parse id with "/subscriptions/" subscription_id "/resourceGroups/" resourceGroup "/providers/Microsoft.Compute/virtualMachines/" *
| where Extensions !contains "AzureMonitor"
| project-away Extensions, status, OSNames
'


#Find the Names from the DCRs
function parseGroupAndName{
    param (
       [string]$resourceID
   )
   $array = $resourceID.Split('/') 
   $indexV = 0..($array.Length -1) | where {$array[$_] -eq 'virtualmachines'}
   $result = $array.get($indexV+1)
   return $result
}

$g = Get-AzDataCollectionRule | Get-AzDataCollectionRuleAssociation | select id
foreach($resourceID in $g){parseGroupAndName -resourceID $resourceID}

#Check for ManagedIdentity
