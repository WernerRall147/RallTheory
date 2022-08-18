#Find All Broken Extensions and remove them

#required Import-Module Az.ResourceGraph

#Resource Graph Query to find all Broken Extensions and sort them va the Server Name
$vmsBrokenExtensions = Search-AzGraph -Query 'resources
| where type == "microsoft.compute/virtualmachines/extensions" and properties.provisioningState != "Succeeded"
| extend 
    VMId = toupper(substring(id, 0, indexof(id, "/extensions"))),
    ExtensionName = tostring(properties.type),
    Provisioned = tostring(properties.provisioningState)
| join kind=leftouter (
resources
| where type == "microsoft.compute/virtualmachines"
| extend
    JoinID = toupper(id),
    OSName = tostring(name),
    SubId = tostring(subscriptionId)
)on $left.VMId == $right.JoinID
| summarize Extensions = make_list(ExtensionName) by OSName, SubId'



