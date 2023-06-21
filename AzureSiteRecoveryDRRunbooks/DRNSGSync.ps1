<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230621
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>
param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext
)

Write-Output "Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

#Log in with the Managed Identity
try
{
    Write-Output "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

#Get all ARM resources from all resource groups
Write-Output "Getting source and destination resource groups..."
$SourceResourceGroup = Get-AZResourcegroup -Name "#TODO"
$DestinationResourceGroup = Get-AZResourcegroup -Name "#TODO"

Write-Output "Getting all NSGs from source and destination resource groups..."
$sourceNetworkSecurityGroup = "#TODO"
$destinationNetworkSecurityGroup = "#TODO"

#Check inbound port rules if NSGs are on Vnets
Write-Output "Get all Source Security Rules"
$sourceSecRules = Get-AzNetworkSecurityGroup -Name $sourceNetworkSecurityGroup  -ResourceGroupName ($SourceResourceGroup).ResourceGroupName
Write-Output "Get all Destination Security Rules"
$destinationSecRules = Get-AzNetworkSecurityGroup -Name $destinationNetworkSecurityGroup  -ResourceGroupName ($DestinationResourceGroup).ResourceGroupName
Write-Output "Comparing Security Rules"
$comp = Compare-Object -ReferenceObject $destinationSecRules.SecurityRules -DifferenceObject $sourceSecRules.SecurityRules -Property Name, Protocol, SourcePortRange, DestinationPortRange, Access, Priority, Direction, ProvisioningState

try {
    if ($null -eq $comp) {
        Write-Output "The rules match"
    } else {
        Write-Output "The rules do not match, trying to repair"
        foreach ($secRule in $sourceSecRules.SecurityRules) {
            $nsg = Get-AzNetworkSecurityGroup -Name ($destinationSecRules).Name -ResourceGroupName ($DestinationResourceGroup).ResourceGroupName
            $ruleConfig = @{
                Name = $secRule.Name
                Access = $secRule.Access
                Protocol = $secRule.Protocol
                Direction = $secRule.Direction
                Priority = $secRule.Priority
                SourceAddressPrefix = $secRule.SourceAddressPrefix
                SourcePortRange = $secRule.SourcePortRange
                DestinationAddressPrefix = $secRule.DestinationAddressPrefix
                DestinationPortRange = $secRule.DestinationPortRange
            }
            $nsg | Add-AzNetworkSecurityRuleConfig @ruleConfig | Set-AzNetworkSecurityGroup
        }
    }
} catch {
    Write-Output "An error occurred: $($_.Exception.Message)"
}