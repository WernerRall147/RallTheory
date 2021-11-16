#request AppID and Secret and create a secure Object
$AppID = "2b89c582-c13a-4b30-b710-71a8fb1c425e"
$Secret = ConvertTo-SecureString "0~zI..Zccp630jlsXNjKsKu4bwhH6oY-oV" -AsPlainText -Force
#Create Credential Object
$credObject = New-Object System.Management.Automation.PSCredential($AppId, $Secret)

#Sign in with Service Principal and query key
# Use the application ID as the username, and the secret as password
Connect-AzAccount -ServicePrincipal -Credential $credObject -Tenant '72f988bf-86f1-41af-91ab-2d7cd011db47' | Out-Null

#get all the Log Analytics Workspace 
$all_workspace = Get-AzOperationalInsightsWorkspace

#here, I hard-code a vm name for testing purpose. If you have more VMs, you can modify the code below using loop.
$allvms = Get-AzVM

#$myvm_name = "vm name"
#$myvm_resourceGroup= "resource group name of the vm"

#for windows vm, the value is fixed as below
$extension_name = "MicrosoftMonitoringAgent"

foreach ($vm in $allvms) {
$myvm = Get-AzVMExtension -ResourceGroupName $vm_resourceGroup -VMName $vm_name -Name $extension_name
$workspace_id = ($vm.PublicSettings | ConvertFrom-Json).workspaceId
}
#$workspace_id

foreach($w in $all_workspace)
{
if($w.CustomerId.Guid -eq $workspace_id)
  { 
  #here, I just print out the vm name and the connected Log Analytics workspace name
  Write-Output "the vm: $($vm_name) writes log to Log Analytics workspace named: $($w.name)"
  }
}
 heart 1

