<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario. These tasks have been split out into seperate scripts

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230517
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>
param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext
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

    foreach($VMID in $VMinfo)
    {
        $VM = $vmMap.$VMID
            if( !(($Null -eq $VM) -Or ($Null -eq $VM.ResourceGroupName) -Or ($Null -eq $VM.RoleName))) {
            #this check is to ensure that we skip when some data is not available else it will fail
            Write-output "Resource group name ", $VM.ResourceGroupName
            }
        }

    #Get all ARM resources from DR
   # $DestinationResourceGroup = Get-AZResourcegroup -Name $VM.ResourceGroupName
    $DestinationResources = Get-AzVM -ResourceGroupName $VM.ResourceGroupName
    $DestinationStorageAccountName = (Get-AzStorageAccount -ResourceGroupName $VM.ResourceGroupName -Name "#TODO").StorageAccountName
    $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $VM.ResourceGroupName -Name $DestinationStorageAccountName).Value[0]

# Ensure Diagnostics Settings are enabled
    try {
    foreach ($drres in $DestinationResources) {
        $DiagSettings = Get-AzVMDiagnosticsExtension -ResourceGroupName $VM.ResourceGroupName -VMName ($drres).Name
        if ($null -eq $DiagSettings) {
            Write-Output "Diagnostics settings are not enabled, trying to remediate"
            $url = "https://raw.githubusercontent.com/WernerRall147/RallTheory/main/AzureSiteRecoveryDRRunbooks/DiagnosticsConfiguration.json"
            $diagnosticsconfig_path = "$env:SystemDrive\temp\DiagnosticsConfiguration.json"
            Invoke-WebRequest -Uri $url -OutFile $diagnosticsconfig_path

            $diagnosticsconfig_update1 = (Get-Content $diagnosticsconfig_path).Replace("(TODOUpdateResID)",$drres.Id) | Set-Content $diagnosticsconfig_path
            $diagnosticsconfig_update2 = (Get-Content $diagnosticsconfig_path).Replace("(TODOUpdateStorac)",$DestinationStorageAccountName) | Set-Content $diagnosticsconfig_path
            $diagnosticsconfig_update1 = (Get-Content $diagnosticsconfig_path).Replace("(TODOUpdateStKey)",$StorageAccountKey) | Set-Content $diagnosticsconfig_path

            Set-AzVMDiagnosticsExtension -ResourceGroupName $VM.ResourceGroupName -VMName ($drres).Name -DiagnosticsConfigurationPath $diagnosticsconfig_path -storageAccountName $DestinationStorageAccountName -StorageAccountKey $StorageAccountKey
            }else {
                Write-Output "Diagnostic Settings Correct"
            }
    }
}
catch {
    Write-Output "An error occurred: $($_.Exception.Message)"
}