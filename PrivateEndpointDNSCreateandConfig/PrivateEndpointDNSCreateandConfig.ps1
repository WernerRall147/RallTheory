<##############Original Script

Set-AzContext -Subscription "sA"
New-AzDiskAccess -ResourceGroupName "rA" -Name "" -Location "lA"

###################Original Script2

Connect-AzAccount

Set-AzContext -Subscription "sA"
$daccname = ""
$resourceid = Get-AzResource -ResourceName "" -ResourceGroupName "rA" #TODO
$resourceid.ResourceId

Set-AzContext -Subscription "sB" #TODO

$rsgname = "rB"
$rsname = ""
$subname = ""
$privatelinkid = $resourceid.ResourceId
$pename = $daccname

$virtualNetwork = Get-AzVirtualNetwork -ResourceName $rsname -ResourceGroupName $rsgname#TODO
$subnet = $virtualNetwork | Select-Object -ExpandProperty subnet | Where-Object Name -eq ""
$plsconnection = New-AzPrivateLinkServiceConnection -Name $pename -privatelinkserviceid $privatelinkid -groupid disks #TODO
New-AzPrivateEndpoint -Name $pename -ResourceGroupName "rC" -Location "" -PrivateLinkServiceConnection $plsconnection -Subnet $subnet

$vnet = Get-AzPrivateEndpoint -ResourceGroupName "rC" -Name $daccname
$name2 = $vnet.CustomDnsConfigs.fqdn #TODO
$ipadress = $vnet.CustomDnsConfigs.ipadresses
$name3 = $name2.Split(".") #TODO
$alias = $name3[0]+"."+$name3[1]
$cname = $name3[0]+".privatelink.blob.core.windows.net"

$privatelinkoutput = $name3[0]+".privatelink.blob.core.windows.net"+$ipadress
Write-Output "........."

Set-AzContext -Subscription "sB" #TODO
New-AzPrivateDnsRecordSet -Name $name3[0] -RecordType A -ResourceGroupName "rB" -Ttl 3600 -ZoneName ".privatelink.blob.core.windows.net" -PrivateDnsRecord ()
New-AzPrivateDnsRecordSet -Name $alias -RecordType CNAME -ResourceGroupName "rB" -Ttl 3600 -ZoneName "blob.storage.azure.net" -PrivateDnsRecord (New-AzPrivateDnsRecordConfig)

########################################################################################################

##Case
# We want to create Private Endpoint and add to Private DNS Zones for Disk Access
#
## What input do I need
## What steps do I need to take
## What is my outcome
#>
[CmdletBinding()]
param (
    #[Parameter()]$AppID = "",
    #[Parameter()]$appSecret = "",
    #[Parameter()]$tenant = "",
    [Parameter()]$location = "",
    [Parameter()]$azResContext,
    [Parameter()]$azSecContext,
    [Parameter()]$daResourceGroup = "",
    [Parameter()]$vnetResourceGroup = "",
    [Parameter()]$plResourceGroup = "",
    [Parameter()]$peResourceName = "",
    [Parameter()]$diskAccessName = "",
   #[Parameter()]$diskAccessObject,
    [Parameter()]$virtualNetwork = "", 
    [Parameter()]$vnetSubnet = "",
    [Parameter()]$peVnetSub
    #[Parameter()]$plsConnection,
    #[Parameter()]$peName,
    #[Parameter()]$customDNSName,
    #[Parameter()]$dnsAlias,
    #[Parameter()]$dnsCName,
    #[Parameter()]$ipadress
)
function azureAuth {
    #request AppID and Secret and create a secure Object
    $Secret = ConvertTo-SecureString $appSecret -AsPlainText -Force
    
    #Create Credential Object
    $credObject = New-Object System.Management.Automation.PSCredential($AppId, $Secret)
    
    # Use the application ID as the username, and the secret as password
    Connect-AzAccount -ServicePrincipal -Credential $credObject -Tenant $tenant | Out-Null
}

function newDiskAccess {
    Set-AzContext -Subscription $azResContext
    New-AzDiskAccess -ResourceGroupName $daResourceGroup -DiskAccessName $diskAccessName -location $location

    $diskAccessObject = Get-AzResource -ResourceName $diskAccessName -ResourceGroupName $daResourceGroup
    #$daResourceId = $diskAccessObject.ResourceId
}

function newPrivateEndpoint {
    Set-AzContext -Subscription $azSecContext
    $virtualNetworkObject = Get-AzVirtualNetwork -Name $virtualNetwork -ResourceGroupName $vnetResourceGroup
    $peVnetSub = $virtualNetworkObject | Select-Object -ExpandProperty Subnets | Where-Object Name -eq $vnetSub

    $plsConnection = New-AzPrivateLinkServiceConnection -Name $diskAccessObject.Name -privatelinkserviceid $diskAccessObject.Id -groupid disks
    New-AzPrivateEndpoint -Name $diskAccessObject.Name -ResourceGroupName $plResourceGroup -Location $location -PrivateLinkServiceConnection $plsconnection -Subnet $peVnetSub
    $pename = Get-AzPrivateEnd point -ResourceGroupName $plResourceGroup -Name $diskAccessObject.Name
    
    $customDNSName = ($pename.CustomDnsConfigs.fqdn).Split(".blob.storage.azure.net")
    $ipadress = $pename.CustomDnsConfigs.ipaddresses
    #$name3 = $name2.Split(".")
    #$dnsAlias = $customDNSName
    $dnsCName = $customDNSName[0]+".privatelink.blob.core.windows.net"

    New-AzPrivateDnsRecordSet -Name $customDNSName[0] -RecordType A -ResourceGroupName $vnetResourceGroup -Ttl 3600 -ZoneName "privatelink.blob.core.windows.net" -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -Ipv4Address $ipadress)
    New-AzPrivateDnsRecordSet -Name $customDNSName[0] -RecordType CNAME -ResourceGroupName $vnetResourceGroup -Ttl 3600 -ZoneName "blob.storage.azure.net" -PrivateDnsRecord (New-AzPrivateDnsRecordConfig -Cname $dnsCName)
    
}

azureAuth
newDiskAccess
newPrivateEndpoint


