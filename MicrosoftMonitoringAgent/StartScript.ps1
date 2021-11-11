#Start a TRanscript of this
Start-Transcript -Path ".\StartScriptResults.txt"

#Connect-azAccount
Connect-AzAccount

#Use AzResourceGraph to get a list of All Machines
#Install-Module -Name Az.ResourceGraph
$myAzureVMs = Search-AzGraph -Query 'resources
| where type == "microsoft.compute/virtualmachines" and properties.storageProfile.osDisk.osType == "Windows"
| where properties.extended.instanceView.powerState.displayStatus=="VM running"
| extend
    JoinID = toupper(id),
    OSName = tostring(name),
    OSType = tostring(properties.storageProfile.osDisk.osType),
    RSG = tostring(resourceGroup),
    SUB = tostring(subscriptionId),
    LOC = tostring(location)
| join kind=leftouter(
resources
| where type == "microsoft.compute/virtualmachines/extensions" and name == "MicrosoftMonitoringAgent"
| extend 
    VMId = toupper(substring(id, 0, indexof(id, "/extensions"))),
    props = tostring(properties.settings)
)on $left.JoinID == $right.VMId
| summarize Extensions = make_list(props) by id, OSName, OSType, RSG, SUB, LOC
'

#Run the scirpt again all VMs in parallel
$myAzureVMs | ForEach-Object -Parallel {
    Set-AzContext -SubscriptionId $_.sub
    $out = Invoke-AzVMRunCommand `
        -ResourceGroupName $_.RSG `
        -Name $_.OSNAME  `
        -CommandId 'RunPowerShellScript' `
        -ScriptPath .\ConnectOMSWorkspaceOS.ps1 
    #Formating the Output with the VM name
    $output = $_.Name + " " + $out.Value[0].Message
    $output   
}

Stop-Transcript