<#
    .DESCRIPTION
        This script is part of the few tasks you might want to run during an Azure Site Recovery DR Scenario set of PowerShell Commands. 
        Even though you can set all the variables manually this script will create the Automation Account Variables for you.
        Please run this script once off from a machine that has Azure Access and the Az PowerShell Module installed.

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230621
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>

param (
[parameter(Mandatory=$true)]
[Object]$AutomationAccountName, 
[parameter(Mandatory=$true)]
[Object]$AutomationAccountResourceGroupName
)

try
{
    Write-Output "Logging in to Azure..."
    Connect-AzAccount
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

try {
    Write-Output "Trying to connect to Fetch Automation Account..."
    Get-AzAutomationAccount -ResourceGroupName $AutomationAccountResourceGroupName -Name $AutomationAccountName | Set-AzAutomationAccount
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

try {
    Write-Output "Creating Variables in Automation Account..."
    New-AzAutomationVariable -Name "recoveryservicesname" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your_Recovery_Services_Vault_Name" -Encrypted $false -Description "The name of the Recovery Services Vault"
    New-AzAutomationVariable -Name "fabricName" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Recovery Services Name for example 'asr-a2a-default-southcentralus'" -Encrypted $false -Description "The name of the Recovery Services Fabric. Get the fabric by running Get-AzRecoveryServicesAsrfabric"
    New-AzAutomationVariable -Name "WorkspaceId" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Log Analytics Workspace ID" -Encrypted $false -Description "The Workspace ID of the Log Analytics Workspace"
    New-AzAutomationVariable -Name "WorkspaceResId" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Log Analytics Resource ID Ex. /subscriptions/xxxxx/resourcegroups/xxxx/providers/microsoft.operationalinsights/workspaces/xxxx" -Encrypted $false -Description "The JSON Resurce ID of the Log Analytics Workspace"
    New-AzAutomationVariable -Name "WorkspaceName" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Log Analytics Workspace Name" -Encrypted $false -Description "The Workspace Name of the Log Analytics Workspace"
    New-AzAutomationVariable -Name "WorkspaceKey" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Log Analytics Workspace Key" -Encrypted $true -Description "The Workspace Key of the Log Analytics Workspace"
    New-AzAutomationVariable -Name "WorkspaceRegion" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Log Analytics Workspace Region" -Encrypted $false -Description "The Workspace Region of the Log Analytics Workspace"
    New-AzAutomationVariable -Name "SubscriptionId" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Subscription ID" -Encrypted $true -Description "The Subscription ID of the Azure Subscription"
    New-AzAutomationVariable -Name "diagnosticsStorageAccountName" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Diagnostics Storage Account Name" -Encrypted $false -Description "The name of the Diagnostics Storage Account"
    New-AzAutomationVariable -Name "actionGroup" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Action Group Name" -Encrypted $false -Description "The name of the Action Group"
    New-AzAutomationVariable -Name "targetRegion" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Target Region" -Encrypted $false -Description "The name of the Target Region"
    New-AzAutomationVariable -Name "SourceResourceGroup" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Source Resource Group" -Encrypted $false -Description "The name of the Source Resource Group"
    New-AzAutomationVariable -Name "DRResourceGroup" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your DR Resource Group Name" -Encrypted $false -Description "The name of the DR Resource Group"
    New-AzAutomationVariable -Name "SourceNetworkSecurityGroup" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "TODO Your Source Network Security Group" -Encrypted $false -Description "The name of the Source Network Security Group"
    New-AzAutomationVariable -Name "destinationNetworkSecurityGroup" -ResourceGroupName $AutomationAccountResourceGroupName -AutomationAccountName $AutomationAccountName -Value "#TODO Your Destination Network Security Group" -Encrypted $false -Description "The name of the Destination Network Security Group"
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

Write-Output "The script has completed with or without errors."