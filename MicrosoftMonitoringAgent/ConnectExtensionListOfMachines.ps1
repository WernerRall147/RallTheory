#Start-Transcript
Start-Transcript -Path "~\Downloads\ConfigureAndConnectWorkspace.txt"
#Import-Csv File
$csv = Import-Csv "~\Downloads\AzureResourceGraphResults-LogAnlyticsWorkspacesVMsConnected.csv"

# Sign in with your admin account
$TenantID = Read-Host "Enter your Tenant ID"
Connect-AzAccount -Tenant $TenantID | Out-Null

#Login-AzAccount
$WsSubID = Read-Host "Enter the subscription where your Log Analytics Workspace is"
$WsLAID = Read-Host "Enter your Log Analytics Workspace ID"
Select-AzSubscription -SubscriptionId "$WsSubID"
$workspaceName = "$WsLAID"

#Get Workspace ID and Keys
$workspace = (Get-AzOperationalInsightsWorkspace).Where({$_.Name -eq $workspaceName})

if ($workspace.Name -ne $workspaceName)
{
    Write-Error "Unable to find OMS Workspace $workspaceName. Do you need to run Select-AzureRMSubscription?"
}
$workspaceId = $workspace.CustomerId
$workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $workspace.ResourceGroupName -Name $workspace.Name).PrimarySharedKey


foreach ($v in $csv)
{
    If ($v.OSType -like "*Windows*"){
Select-AzSubscription -SubscriptionId "$v.sub"
az vm extension set --resource-group "$v.RSG" --vm-name "$v.OSNAME" --name MicrosoftMonitoringAgent --publisher Microsoft.EnterpriseCloud.Monitoring --protected-settings {"workspaceKey":"$workspaceKey"} --settings {"workspaceId":"$workspaceId"}
Write-Host "$v.OSNAME Windows VM has been updated"
}
else
{
 For Linux VM uncomment the following line
Select-AzSubscription -SubscriptionId "$v.sub"
az vm extension set --resource-group "$v.RSG" --vm-name "$v.OSNAME" --name OmsAgentForLinux --publisher Microsoft.EnterpriseCloud.Monitoring --protected-settings {"workspaceKey":"$workspaceKey"} --settings {"workspaceId":"$workspaceId"}
Write-Host "$v.OSNAME Linux VM has been updated"
}
}

Stop-Transcript