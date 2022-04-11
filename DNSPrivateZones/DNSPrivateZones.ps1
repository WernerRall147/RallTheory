#Require-Module -Name Az.PrivateDns
$TenantID = Read-host -Prompt "Please enter your Tenant ID"
$SubID = Read-host -Prompt "Please enter your subscription ID"
$RSG = Read-host -Prompt "Please enter your Recource Group Name that contains your virtual network"
$VnetName = Read-host -Prompt "Please enter your Virtual Network Name"
$SubNet = Read-host -Prompt "Please enter your Virtual Network Subnet Name"

Connect-AzAccount -Tenant $TenantID -SubscriptionID $subID

$csv = import-csv -Path .\PrivateDNSZones.csv

$vnet = get-AzVirtualNetwork -ResourceGroupName $RSG -Name $VnetName


foreach($z in $csv){
New-AzPrivateDnsZone -Name $z.PrivateDNSzonename -ResourceGroupName $vnet.ResourceGroupName
New-AzPrivateDnsVirtualNetworkLink -ZoneName $z.PrivateDNSzonename -ResourceGroupName $vnet.ResourceGroupName -Name "HubLink" -VirtualNetworkId $vnet.Id
}
