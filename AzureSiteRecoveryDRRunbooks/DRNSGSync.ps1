<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230822
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>
param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext, 
[parameter(Mandatory=$false)]
[string]$DRResourceGroup = "#TODO Destination Resource group for alerts",
[parameter(Mandatory=$false)]
[string]$SourceResourceGroup = "#TODO Source Resource group for alerts",
[parameter(Mandatory=$false)]
[string]$DRNetworkSecurityGroup = "#TODO Destination Network Security Group for rules",
[parameter(Mandatory=$false)]
[string]$SourceNetworkSecurityGroup = "#TODO Source Network Security Group for rules"
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

Write-Output "Getting variables from Automation Account Store"
$DRResourceGroup = Get-AutomationVariable -Name 'DRResourceGroup'
$SourceResourceGroup = Get-AutomationVariable -Name 'SourceResourceGroup'
$DRNetworkSecurityGroup = Get-AutomationVariable -Name 'destinationNetworkSecurityGroup'
$SourceNetworkSecurityGroup = Get-AutomationVariable -Name 'SourceNetworkSecurityGroup'


#Check inbound port rules if NSGs are on Vnets
Write-Output "Get all Source Security Rules"($sourceSecRules = Get-AzNetworkSecurityGroup -Name $SourceNetworkSecurityGroup  -ResourceGroupName ($SourceResourceGroup).ResourceGroupName)
Write-Output "Get all Destination Security Rules"($destinationSecRules = Get-AzNetworkSecurityGroup -Name $destinationNetworkSecurityGroup  -ResourceGroupName ($DRResourceGroup).ResourceGroupName)
Write-Output "Comparing Security Rules"
Write-Output ($comp = Compare-Object -ReferenceObject $destinationSecRules.SecurityRules -DifferenceObject $sourceSecRules.SecurityRules -Property Name, Protocol, SourcePortRange, DestinationPortRange, Access, Priority, Direction, ProvisioningState)

try {
    if ($null -eq $comp) {
        Write-Output "The rules match"
    } else {
        Write-Output "The rules do not match, trying to repair"
        foreach ($secRule in $sourceSecRules.SecurityRules) {
            $nsg = Get-AzNetworkSecurityGroup -Name ($destinationSecRules).Name -ResourceGroupName ($DRResourceGroup).ResourceGroupName
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
            Write-Output ($nsg | Add-AzNetworkSecurityRuleConfig @ruleConfig | Set-AzNetworkSecurityGroup)
        }
    }
} catch {
    Write-Output "An error occurred: $($_.Exception.Message)"
}

Write-Output "The script has completed with or without errors."