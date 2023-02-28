<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: Oct 26, 2021
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>

"Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

#Log in with the Managed Identity
try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

#Get all ARM resources from all resource groups
$SourceResourceGroup = Get-AZResourcegroup -Name "#TODO"
$DestinationResourceGroup = Get-AZResourcegroup -Name "#TODO"

$sourceNetworkSecurityGroup = "#TODO"
$destinationNetworkSecurityGroup = "#TODO" 

#Check inbound port rules if NSGs are on Vnets
$sourceSecRules = Get-AzNetworkSecurityGroup -Name $sourceNetworkSecurityGroup  -ResourceGroupName ($SourceResourceGroup).ResourceGroupName 
$destinationSecRules = Get-AzNetworkSecurityGroup -Name $destinationNetworkSecurityGroup  -ResourceGroupName ($DestinationResourceGroup).ResourceGroupName 

if($sourceSecRules.SecurityRules -eq $destinationSecRules.SecurityRules){
Write-Output "The rules match"
}else {
Write-Output "The rules do not match, trying to repair"
foreach($secRule in $sourceSecRules.SecurityRules){ 
    Get-AzNetworkSecurityGroup -Name ($destinationSecRules).Name -ResourceGroupName ($DestinationResourceGroup).ResourceGroupName  | Add-AzNetworkSecurityRuleConfig `
        -Name $secRule.Name `
        -Access $secRule.Access `
        -Protocol $secRule.Protocol `
        -Direction $secRule.Direction `
        -Priority $secRule.Priority `
        -SourceAddressPrefix $secRule.SourceAddressPrefix `
        -SourcePortRange $secRule.SourcePortRange `
        -DestinationAddressPrefix $secRule.DestinationAddressPrefix `
        -DestinationPortRange $secRule.DestinationPortRange `
        | Set-AzNetworkSecurityGroup

    }
}