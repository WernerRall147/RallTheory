# Set variables
param (
[Parameter(Mandatory=$false)]$resourceGroupName = " ",
[Parameter(Mandatory=$false)]$serviceName = " ",
[Parameter(Mandatory=$false)]$privateEndpointName = " ",
[Parameter(Mandatory=$false)]$privateLinkServiceName = " ",
[Parameter(Mandatory=$false)]$subscriptionID = " ",
[Parameter(Mandatory=$false)]$virtualNetwork = " ",
[Parameter(Mandatory=$false)]$subnet = " "
)

# Login to Azure
Connect-AzAccount

function newPrivateEndpoint {
    #Get the Service
    $servName = Get-AzResource -Name $serviceName
    $servId = (Get-AzResource -Name $serviceName).ResourceId

    $virtualNetworkObject = Get-AzVirtualNetwork -Name $virtualNetwork
    $peVnetSub = $virtualNetworkObject | Select-Object -ExpandProperty Subnets | Where-Object Name -eq $subnet

    $plsConnection = New-AzPrivateLinkServiceConnection -Name $servName.Name -privatelinkserviceid $servId -groupid $servId
    New-AzPrivateEndpoint -Name $servName.Name -ResourceGroupName $resourceGroupName -Location $virtualNetworkObject.Location -PrivateLinkServiceConnection $plsconnection -Subnet $peVnetSub
    $pename = Get-AzPrivateEndpoint -ResourceGroupName $resourceGroupName -Name $servName.Name
    
    $customDNSName = ($pename.CustomDnsConfigs.fqdn).Split(".blob.storage.azure.net")
    $ipadress = $pename.CustomDnsConfigs.ipaddresses
    $dnsCName = $customDNSName[0]+".privatelink.blob.core.windows.net"

    New-AzPrivateDnsRecordSet -Name $customDNSName[0] -RecordType A -ResourceGroupName $vnetResourceGroup -Ttl 3600 -ZoneName "privatelink.blob.core.windows.net" -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -Ipv4Address $ipadress)
    New-AzPrivateDnsRecordSet -Name $customDNSName[0] -RecordType CNAME -ResourceGroupName $vnetResourceGroup -Ttl 3600 -ZoneName "blob.storage.azure.net" -PrivateDnsRecord (New-AzPrivateDnsRecordConfig -Cname $dnsCName)

    $dnsZoneObject = Get-AzPrivateDnsZone -ResourceGroupName $vnetResourceGroup -Name 'privatelink.blob.core.windows.net'
    $dnszoneConfig = New-AzPrivateDnsZoneConfig -Name 'privatelink.blob.core.windows.net' -PrivateDnsZoneId $dnsZoneObject.ResourceId
    Set-AzPrivateDnsZoneGroup -Name 'default' -ResourceGroupName $vnetResourceGroup -PrivateEndpointName $diskAccessObject.Name -PrivateDnsZoneConfig $dnszoneConfig

}

newPrivateEndpoint