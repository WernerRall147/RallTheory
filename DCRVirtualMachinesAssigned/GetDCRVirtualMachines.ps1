#VM, AMA, MI, DCR
#vm1, Y, N, WhichDCR

#Section 1 (added this to Section 2)
#Check for ManagedIdentity
$subs = Get-AzSubscription -TenantId (Read-Host "Insert your tenant ID") | Where-Object {$_.state -ne "Disabled"}

foreach($s in $subs){
$AllVMs += Get-AzVM | select Id,Name,Identity
}

foreach($v in $AllVMs){
if ($v.Identity -eq $NULL) {
    write-host "Server does not have a managed identity"
}else{
    Write-host "Server has a managed identity"
}
}

#Section 2
#find the Machines with AMA Installed
$AMASearch = Search-AzGraph -Query '
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
    powerState,
    identity = tostring(properties.identity)
| join kind=leftouter(
    Resources | where type == "microsoft.compute/virtualmachines/extensions"
    | project
        MachineId = toupper(substring(id, 0, indexof(id, "/extensions"))),
        ExtensionName = name
) on $left.JoinID == $right.MachineId
| summarize Extensions = make_list(ExtensionName) by id, OSName, status, machineName, osType, location, powerState, identity
| parse id with "/subscriptions/" subscription_id "/resourceGroups/" resourceGroup "/providers/Microsoft.Compute/virtualMachines/" *
| where Extensions !contains "AzureMonitor"
| project-away Extensions, status, OSName
'

#Add custom NoteProperty HasAMA = No
foreach($e in $AMASearch){
    $e | Add-Member -type NoteProperty -name HasAMA -value No
}

#Section 3
#Find the Names from the DCRs

Foreach($wspc in $allworkspaces)
{
$wspcID = $wspc.CustomerID
$wspcKey = (Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $wspc.ResourceGroupName -Name $wspc.Name).PrimarySharedKey
$workspaceHtable += @{$wspcID="$wspcKey"}
}

$dcrs = Get-AzDataCollectionRule | Get-AzDataCollectionRuleAssociation 
function parseName{
    param (
       [string]$resourceID,
       [string]$dceerID
   )
   $array = $resourceID.Split('/') 
   $indexV = 0..($array.Length -1) | where {$array[$_] -eq 'virtualmachines'}
   $array = $dceer.Split('/')
   $indexG = 0..($array.Length -1) | where {$array[$_] -eq 'datacollectionrules'}
   $result = $array.get($indexV+1),$array.get($indexG+1)
   return $result
}

$vmid = $dcrs | select Id
foreach($resourceID in $vmid){parseName -resourceID $resourceID}

function parseDcr{
    param (
       [string]$resourceID
   )
   $array = $resourceID.Split('/') 
   $indexG = 0..($array.Length -1) | where {$array[$_] -eq 'datacollectionrules'}
   $result = $array.get($indexG+1)
   return $result
}

$dcrid = $dcrs | select DataCollectionRuleId
foreach($resourceID in $dcrid){parseDcr -resourceID $resourceID}