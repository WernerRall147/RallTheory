<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230302
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
$DestinationResourceGroup = Get-AZResourcegroup -Name "#TODO"
$DestinationResources = Get-AZResource -ResourceGroupName $DestinationResourceGroup
$Location = ($DestinationResourceGroup).Location

# Ensure insights get enabled
#Install-Script -Name Install-VMInsights
foreach($drres in $DestinationResources){
    $WorkspaceId = "#TODO"
    $WorkspaceKey = "#TODO"
    .\Install-VMInsights.ps1 -WorkspaceId $WorkspaceId -WorkspaceKey $WorkspaceKey -SubscriptionId SubscriptionId -WorkspaceRegion $Location -Approve
    }