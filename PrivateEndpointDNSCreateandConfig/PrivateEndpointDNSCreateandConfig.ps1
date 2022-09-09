##Case
# We want to create Private Endpoint and add to Private DNS Zones for Disk Access
#
## What input do I need
## What steps do I need to take
## What is my outcome
#
[CmdletBinding()]
param (
    #[Parameter()]$AppID = "",
    #[Parameter()]$appSecret = "",
    #[Parameter()]$tenant = "",
    [Parameter(Mandatory=$true)]$location = "",
    [Parameter(Mandatory=$true)]$azResContext,
    [Parameter(Mandatory=$true)]$azSecContext,
    [Parameter(Mandatory=$true)]$daResourceGroup = "",
    [Parameter(Mandatory=$true)]$vnetResourceGroup = "",
    [Parameter(Mandatory=$true)]$plResourceGroup = "",
    [Parameter(Mandatory=$true)]$peResourceName = "",
    [Parameter(Mandatory=$true)]$diskAccessName = "",
    #[Parameter()]$diskAccessObject,
    [Parameter(Mandatory=$true)]$virtualNetwork = "", 
    [Parameter(Mandatory=$true)]$vnetSubnet = "",
    [Parameter(Mandatory=$true)]$peVnetSub = ""
    #[Parameter()]$plsConnection,
    #[Parameter()]$peName,
    #[Parameter()]$customDNSName,
    #[Parameter()]$dnsAlias,
    #[Parameter()]$dnsCName,
    #[Parameter()]$ipadress,
    #[Parameter()]$dnsZoneObject,
    #[Parameter()]$dnszoneConfig
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
    #Set-AzContext -Subscription $azResContext
    New-AzDiskAccess -ResourceGroupName $daResourceGroup -DiskAccessName $diskAccessName -location $location

    $diskAccessObject = Get-AzResource -ResourceName $diskAccessName -ResourceGroupName $daResourceGroup
    #$daResourceId = $diskAccessObject.ResourceId
}

function newPrivateEndpoint {
    #Set-AzContext -Subscription $azSecContext
    $virtualNetworkObject = Get-AzVirtualNetwork -Name $virtualNetwork -ResourceGroupName $vnetResourceGroup
    $peVnetSub = $virtualNetworkObject | Select-Object -ExpandProperty Subnets | Where-Object Name -eq $vnetSubnet

    $plsConnection = New-AzPrivateLinkServiceConnection -Name $diskAccessObject.Name -privatelinkserviceid $diskAccessObject.Id -groupid disks
    New-AzPrivateEndpoint -Name $diskAccessObject.Name -ResourceGroupName $plResourceGroup -Location $location -PrivateLinkServiceConnection $plsconnection -Subnet $peVnetSub
    $pename = Get-AzPrivateEndpoint -ResourceGroupName $plResourceGroup -Name $diskAccessObject.Name
    
    $customDNSName = ($pename.CustomDnsConfigs.fqdn).Split(".blob.storage.azure.net")
    $ipadress = $pename.CustomDnsConfigs.ipaddresses
    $dnsCName = $customDNSName[0]+".privatelink.blob.core.windows.net"

    New-AzPrivateDnsRecordSet -Name $customDNSName[0] -RecordType A -ResourceGroupName $vnetResourceGroup -Ttl 3600 -ZoneName "privatelink.blob.core.windows.net" -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -Ipv4Address $ipadress)
    New-AzPrivateDnsRecordSet -Name $customDNSName[0] -RecordType CNAME -ResourceGroupName $vnetResourceGroup -Ttl 3600 -ZoneName "blob.storage.azure.net" -PrivateDnsRecord (New-AzPrivateDnsRecordConfig -Cname $dnsCName)

    $dnsZoneObject = Get-AzPrivateDnsZone -ResourceGroupName $vnetResourceGroup -Name 'privatelink.blob.core.windows.net'
    $dnszoneConfig = New-AzPrivateDnsZoneConfig -Name 'privatelink.blob.core.windows.net' -PrivateDnsZoneId $dnsZoneObject.ResourceId
    New-AzPrivateDnsZoneGroup -Name 'default' -ResourceGroupName $vnetResourceGroup -PrivateEndpointName $diskAccessObject.Name -PrivateDnsZoneConfig $dnszoneConfig 

}

azureAuth
newDiskAccess
newPrivateEndpoint

