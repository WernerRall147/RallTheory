<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario. These tasks have been split out into seperate scripts

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
$DestinationResourceGroup = Get-AZResourcegroup -Name "#TODO"
$DestinationResources = Get-AZResource -ResourceGroupName $DestinationResourceGroup

# Ensure Diagnostics Settings are enabled
foreach ($drres in $DestinationResources) {

    $resId = $drres.Id
    $DiagSettings = Get-AzDiagnosticSetting -ResourceId $resId 
    if ($DiagSettings -eq $null) {
        Write-Output "Diagnostics settings are not enabled, trying to remediate"
        
        $url = "https://raw.githubusercontent.com/WernerRall147/RallTheory/main/AzureSiteRecoveryDRRunbooks/diagnostics_publicconfig.xml"
        $diagnosticsconfig_path = "$env:SystemDrive\temp\DiagnosticsPubConfig.xml"
        Invoke-WebRequest -Uri $url -OutFile $dest

        $diagnosticsconfig_update1 = (Get-Content $diagnosticsconfig_path).Replace("(TODOUpdateResID)",$drres.Id) | Set-Content $path 
        $diagnosticsconfig_update2 = (Get-Content $diagnosticsconfig_path).Replace("(TODOUpdateStorac)",$DestinationStorageAccountName) | Set-Content $path 

        Set-AzVMDiagnosticsExtension -ResourceGroupName ($DestinationResources).ResourceGroupName -VMName ($drres).Name -DiagnosticsConfigurationPath $diagnosticsconfig_path
        }else {
            Write-Output "Diagnostic Settings Correct"
        }
}    