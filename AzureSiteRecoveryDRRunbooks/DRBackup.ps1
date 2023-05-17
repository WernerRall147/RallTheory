<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230517
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>
param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext
)

#"Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."
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

#Decyfer RecoveryPlan Context
$VMinfo = $RecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
$vmMap = $RecoveryPlanContext.VmMap

try{
foreach($VMID in $VMinfo)
{
    $VM = $vmMap.$VMID                
        if( !(($VM -eq $Null) -Or ($VM.ResourceGroupName -eq $Null) -Or ($VM.RoleName -eq $Null))) {
        #this check is to ensure that we skip when some data is not available else it will fail
        Write-output "The Resource group name ", $VM.ResourceGroupName
        Write-output "The current Server name is ", $VM.RoleName

        # Ensure Backup gets enabled
        $vault = Get-AzRecoveryServicesVault -ResourceGroupName $VM.ResourceGroupName | Set-AzRecoveryServicesVaultContext
        $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy"

        Enable-AzRecoveryServicesBackupProtection `
            -ResourceGroupName $VM.ResourceGroupName `
            -Name $VM.RoleName `
            -Policy $policy `
            -WhatIf
        }
        else {
            Write-Error "Something went wrong when we tried to enable backup on $VM"
        }
    }
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}


