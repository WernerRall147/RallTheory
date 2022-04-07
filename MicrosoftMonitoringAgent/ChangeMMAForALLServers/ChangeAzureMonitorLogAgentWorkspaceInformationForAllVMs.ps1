Connect-AzAccount

$managementGroupName = Read-Host -prompt "What is your Management Group Name"
$subscriptionsGraph = Search-AzGraph -Query 'ResourceContainers | where type =~ "microsoft.resources/subscriptions"' -ManagementGroup $managementGroupName

$workspaceId='Your workspace Id'
$workspaceKey='Your workspace key'

$secureKey=ConvertTo-SecureString -String $workspaceKey -AsPlainText -Force

$extensionList=@()
Foreach($s in $subscriptionsGraph){
Set-AzContext -SubscriptionId $s.subscriptionId
$extensionList += Get-AzVm | foreach {
    Get-AzVMExtension -ResourceGroupName $_.ResourceGroupName -VMName $_.Name -ExtensionName "MicrosoftMonitoringAgent"
}
}

$PublicSettings = @{"workspaceId" = $workspaceId}
$ProtectedSettings = @{"workspaceKey" = $workspaceKey}

Write-Host $extensionList.count 
$jobs=@()
$extensionList | foreach {
    $jobs += Set-AzVMExtension -ExtensionName $_.Name `
-ResourceGroupName $_.ResourceGroupName `
-VMName $_.VMName `
-Publisher $_.Publisher `
-ExtensionType $_.ExtensionType `
-TypeHandlerVersion 1.0 `
-Settings $PublicSettings `
-ProtectedSettings $ProtectedSettings `
-Location $_.Location -AsJob
}
Receive-Job -Job $jobs -Wait