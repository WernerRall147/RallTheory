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

#Decyfer RecoveryPlan Context
Write-Output "Getting Recovery Plan context"
$VMinfo = $RecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | Select-Object -ExpandProperty Name
$vmMap = $RecoveryPlanContext.VmMap
$DRResourceGroup = Get-AutomationVariable -Name 'DRResourceGroup'

Write-Output "for Each VM trying to enable Backup on the VMs"
try{
foreach($VMID in $VMinfo)
{
    $VM = $vmMap.$VMID                
        if( !(($Null -eq $VM) -Or ($Null -eq $VM.ResourceGroupName) -Or ($Null -eq $VM.RoleName))) {
        #this check is to ensure that we skip when some data is not available else it will fail
        Write-output "The Resource group name ", $VM.ResourceGroupName
        Write-output "The current Server name is ", $VM.RoleName

        # Ensure Backup gets enabled
        Write-Output "Get Az Recovery Services Vault"($vault = Get-AzRecoveryServicesVault -ResourceGroupName $DRResourceGroup | Set-AzRecoveryServicesVaultContext)
        Write-Output $vault
        Write-Output "Get Az Recovery Services Backup Protection Policy"($policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy")
        Write-Output "Enable Backup on the VMs" (Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $DRResourceGroup -Name $VM.RoleName -Policy $policy)
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

Write-Output "The script has completed with or without errors."
