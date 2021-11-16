#request AppID and Secret and create a secure Object
$AppID = ""
$Secret = ConvertTo-SecureString "" -AsPlainText -Force
#Create Credential Object
$credObject = New-Object System.Management.Automation.PSCredential($AppId, $Secret)

#Sign in with Service Principal and query key
# Use the application ID as the username, and the secret as password
Connect-AzAccount -ServicePrincipal -Credential $credObject -Tenant '' | Out-Null

#get all the Log Analytics Workspace 
$all_workspace = Get-AzOperationalInsightsWorkspace

#here, I hard-code a vm name for testing purpose. If you have more VMs, you can modify the code below using loop.
$allvms = Get-AzVM | select *


#$myvm_name = "vm name"
#$myvm_resourceGroup= "resource group name of the vm"

#for windows vm, the value is fixed as below
$extension_name = "MicrosoftMonitoringAgent"
$extension_linux = "OMSAgentforLinux"

if($allVms.LicenseType -eq "Windows_Server"){
foreach ($vm in $allvms) {
$myvm = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name $extension_name
$workspace_id = ($myvm.PublicSettings | ConvertFrom-Json).workspaceId
}
}else{
  foreach ($vm in $allvms) {
    $myvm = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name $extension_linux
    $workspace_id = ($myvm.PublicSettings | ConvertFrom-Json).workspaceId
    }
}
#$workspace_id

foreach($w in $all_workspace)
{
if($w.CustomerId.Guid -eq $workspace_id)
  { 
  #here, I just print out the vm name and the connected Log Analytics workspace name
  Write-Output "the vm: $($vm.Name) writes log to Log Analytics workspace named: $($w.name)"
  }
}

