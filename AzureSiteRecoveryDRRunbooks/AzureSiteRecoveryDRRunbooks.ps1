<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: Oct 26, 2021
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
        Included variables in this context
        Variable name	            Description
        RecoveryPlanName	Recovery plan name. Used in actions based on the name.
        FailoverType	            Specifies whether it's a test or production failover.
        FailoverDirection	        Specifies whether recovery is to a primary or secondary location.
        GroupID	                        Identifies the group number in the recovery plan when the plan is running.
        VmMap	                       An array of all VMs in the group.
        VMMap key	                A unique key (GUID  ) for each VM.
        SubscriptionId	            The Azure subscription ID in which the VM was created.
        ResourceGroupName	Name of the resource group in which the VM is located.
        CloudServiceName	    The Azure cloud service name under which the VM was created.
        RoleName	                    The name of the Azure VM.
        RecoveryPointId	            The timestamp for the VM recovery.
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

$SourceResources = Get-AZResource -ResourceGroupName $SourceResourceGroup.Name
$DestinationResources = Get-AZResource -ResourceGroupName $DestinationResourceGroup.Name

$SourceVirtualNetwork = "#TODO"
$DestinationVirtualNetwork = "#TODO"

$sourceNetworkSecurityGroup = "#TODO"
$destinationNetworkSecurityGroup = "#TODO"

#Check inbound port rules if NSGs are on Vnets
#
$sourceSecRules = Get-AzNetworkSecurityGroup -Name $sourceNetworkSecurityGroup  -ResourceGroupName $SourceResourceGroup.Name
$destinationSecRules = Get-AzNetworkSecurityGroup -Name $destinationNetworkSecurityGroup  -ResourceGroupName $DestinationResourceGroup.Name
if($sourceSecRules -eq $destinationSecRules){
Write-Output "The rules match"
}else {
Write-Output "The rules do not match, trying to repair"
    foreach($secRule in $sourceSecRules){
        Add-AzNetworkSecurityRuleConfig `
        -Name $secRule.Name `
        -NetworkSecurityGroup $destinationNetworkSecurityGroup `
        -Description $secRule.Description `
        -Access $secRule.Access `
        -Protocol $secRule.Protocol `
        -Direction $secRule.Direction `
        -Priority $secRule.Priority `
        -SourceAddressPrefix $secRule.SourceAddressPrefix `
        -SourcePortRange $secRule.SourcePortRange `
        -DestinationAddressPrefix $secRule.DestinationAddressPrefix `
        -DestinationPortRange $secRule.DestinationPortRange

        Set-AzNetworkSecurityGroup -NetworkSecurityGroup $networkSecurityGroup -Verbose
    }
}

# Check inbound port rules for VMs in the Virtual Networks if NSGs are on Servers


# Check VM Sizes
foreach ($res in $SourceResources) {
    $sourcevmsize = Get-AzVMSize -Location $SourceResourceGroup.location -VMName $res
    $destinationvmsize = Get-AzVMSize -Location $DestinationResourceGroup.location -VMName $res
    
    
}    

# Ensure Diagnostics Settings are enabled
#https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/diagnostics-windows
foreach ($res in $SourceResources) {
    $resId = $res.ResourceId
    $DiagSettings = Get-AzDiagnosticSetting -ResourceId $resId  | Where-Object { $_.Id -eq $null }
    Set-AzVMDiagnosticsExtension -ResourceGroupName $SourceResources.ResourceGroupName -VMName $res
}    

# Ensure Backup gets enabled
#https://learn.microsoft.com/en-us/azure/backup/quick-backup-vm-powershell
$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy"

foreach ($drres in $DestinationResources) {
Enable-AzRecoveryServicesBackupProtection `
    -ResourceGroupName $DestinationResourceGroup `
    -Name $res `
    -Policy $policy
}

# Ensure insights get enabled
#https://learn.microsoft.com/en-us/azure/azure-monitor/vm/vminsights-enable-powershell
#Install-Script -Name Install-VMInsights	
foreach($drres in $DestinationResources){
$WorkspaceId = "#TODO"
$WorkspaceKey = "#TODO"
$SubscriptionId = "SubscriptionId"
.\Install-VMInsights.ps1 -WorkspaceId $WorkspaceId -WorkspaceKey $WorkspaceKey -SubscriptionId $SubscriptionId -WorkspaceRegion $DestinationResourceGroup.location -ResourceGroup $DestinationResourceGroup.Name -ReInstall
}




