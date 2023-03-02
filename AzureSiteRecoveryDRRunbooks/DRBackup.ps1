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

# Ensure Backup gets enabled
$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy"

foreach ($res in $DestinationResourceGroup) {
Enable-AzRecoveryServicesBackupProtection `
    -ResourceGroupName ($DestinationResourceGroup).ResourceGroupName `
    -Name $res `
    -Policy $policy
}