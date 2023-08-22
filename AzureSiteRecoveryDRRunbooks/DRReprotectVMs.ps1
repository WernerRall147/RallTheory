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
[string]$recoveryservicesname = "#TODO Your_Recovery_Services_Vault_Name",

[parameter(Mandatory=$false)]
[string]$fabricName = "#TODO Your Recovery Services Name for example 'asr-a2a-default-southcentralus'"
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
$recoveryservicesname = Get-AutomationVariable -Name 'recoveryservicesname'
$fabricName = Get-AutomationVariable -Name 'fabricName'

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
            Write-Output (vault = Get-AzRecoveryServicesVault -Name $recoveryservicesname -ResourceGroupName $VM.ResourceGroupName)

            # Set the vault context
            Write-Output (Set-AzRecoveryServicesAsrVaultSettings -Vault $vault)

            # Get the Replication Protected Item
            # Get the ASR Fabric and select one based on a condition
            Write-Output ($fabric = Get-AzRecoveryServicesAsrFabric -Name $fabricName)
            Write-Output ($protectionContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric)
            Write-Output ($replicatedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $protectionContainer)

            # Start reprotecting the VM
            Write-Output (Start-AzRecoveryServicesAsrReprotect -ReplicationProtectedItem $replicatedItem)

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

    Write-Output "The script has completed with or without errors."