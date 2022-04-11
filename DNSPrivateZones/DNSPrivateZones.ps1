Connect-AzAccount

Install-Module -Name Az.PrivateDns -force

$backendSubnet = get-AzVirtualNetworkSubnetConfig -Name PVTE `
$vnet = get-AzVirtualNetwork -ResourceGroupName vTec-IaaS-Hub -Location UKSouth `
-Name cakepokeruk -AddressPrefix 10.0.2.0/16 -Subnet $backendSubnet `

New-AzPrivateDnsZone -Name privatelink.azure-automation.cn -ResourceGroupName vTec-IaaS-Hub

New-AzPrivateDnsVirtualNetworkLink -ZoneName privatelink.azure-automation.cn `
-ResourceGroupName vTec-IaaS-Hub `
-Name -VirtualNetworkId 3fd83162-8ced-40c6-bd0d-de790ac03a06