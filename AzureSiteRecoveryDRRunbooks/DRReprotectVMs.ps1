<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230605
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>
param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext, 

[parameter(Mandatory=$false)]
[string]$recoveryservicesname = "#TODO Your_Recovery_Services_Vault_Name",

#get the fabric by running Get-AzRecoveryServicesAsrfabric which is needed for below scripts
[parameter(Mandatory=$false)]
[string]$fabricName = "#TODO Your Recovery Services Name for example 'asr-a2a-default-southcentralus'"
)

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


#Decyfer RecoveryPlan Context
$VMinfo = $RecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | Select-Object -ExpandProperty Name
$vmMap = $RecoveryPlanContext.VmMap

try{
    foreach($VMID in $VMinfo)
    {
        $VM = $vmMap.$VMID                
            if( !(($Null -eq $VM) -Or ($Null -eq $VM.ResourceGroupName) -Or ($Null -eq $VM.RoleName))) {
            #this check is to ensure that we skip when some data is not available else it will fail
            Write-output "The Resource group name ", $VM.ResourceGroupName
            Write-output "The current Server name is ", $VM.RoleName
    
            # Ensure Reprotection and Replication get enabled         
            # Get the recovery services vault
            $vault = Get-AzRecoveryServicesVault -Name $recoveryservicesname -ResourceGroupName $VM.ResourceGroupName

            # Set the vault context
            Set-AzRecoveryServicesAsrVaultSettings  -Vault $vault

            # Get the Replication Protected Item
            # Get the ASR Fabric and select one based on a condition
            $fabric = Get-AzRecoveryServicesAsrFabric -Name $fabricName
            $protectionContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric
            $replicatedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $protectionContainer

            # Start reprotecting the VM
            Start-AzRecoveryServicesAsrReprotect -ReplicationProtectedItem $replicatedItem

            }
            else {
                Write-Error "Something went wrong when we tried to reprotect $VM"
            }
        }
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }