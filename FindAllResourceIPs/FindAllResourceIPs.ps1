#Requires -Modules Az

#Connect-azAccount
Connect-AzAccount

$allResourceP = ()
$allsubs = Get-azsubscription
foreach ($sub in $allResourceP) {
    Get-AzResourceProvider

}

If(RP namespace duplicate)
{
Dont add to hashtable
}

#Build graph query
$PossibleIPConfig = "These resource types can contain and IP address"

$ResourceTypes = "Choose from $allResourceP which ones will be put in the query"

#Build Graph Query that contains the word IP addresses
$QueryAllIPs = Search-AzGraph -Query '
resources
| where properties matches regex @"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
|project  name, type, location, resourceGroup, subscriptionId, properties
'