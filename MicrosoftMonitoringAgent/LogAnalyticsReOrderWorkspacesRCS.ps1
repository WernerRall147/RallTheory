#----------------------------------------------------------------------------------------------------------------------------------------
#This Section Recieves all the Azure Information
#----------------------------------------------------------------------------------------------------------------------------------------
#Check if correct Modules are loaded
    #TLS Settings for PowerShellGet
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Install-Module -Name Az.OperationalInsights -Repository PSGallery -Force -ErrorAction Stop
    Import-Module -Name Az.OperationalInsights -ErrorAction Stop
    Install-Module -Name Az.Accounts -Repository PSGallery -Force -ErrorAction Stop
    Import-Module -Name Az.Accounts -ErrorAction Stop


#Sign in with Service Principal and query key Use the application ID as the username, and the secret as password
#
#

#request AppID and Secret and create a secure Object
$AppID = "appID"
$Secret = ConvertTo-SecureString "appSecret" -AsPlainText -Force
#Create Credential Object
$credObject = New-Object System.Management.Automation.PSCredential($AppId, $Secret)

#Sign in with Service Principal and query key
# Use the application ID as the username, and the secret as password
Connect-AzAccount -ServicePrincipal -Credential $credObject -Tenant '' | Out-Null

#get this VM in Azure
#$vm = Get-AzVM -VMName "$env:COMPUTERNAME"

#get keys and workspaces
$allworkspaces = Get-AzOperationalInsightsWorkspace

#Create Hashtable
$workspaceHtable = @{}

#Get Workspace IDs
Foreach($wspc in $allworkspaces)
{
$wspcID = $wspc.CustomerID
$wspcKey = (Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $wspc.ResourceGroupName -Name $wspc.Name).PrimarySharedKey
$workspaceHtable += @{$wspcID="$wspcKey"}
}

#Enumerate Update Compliance workspace details. 
$UCworkspaces = @(
#First Workspace
("WSID", "Key")
)
#----------------------------------------------------------------------------------------------------------------------------------------
#This Section Configures the Local Host Machines
#----------------------------------------------------------------------------------------------------------------------------------------
#Create MMA Object on Machine
Write-Host "Starting Log Analytics Configuration"
$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'

#Get current Cloud Workspaces
$mmawsps = @(
$mma.GetCloudWorkspaces()
)

#Get current Cloud Workspaces Keys and add a new property to the Array for the 
foreach($cwsps in $mmawsps)
{
If ($cwsps.workspaceId -in $workspaceHtable.Keys)
{
$match_key = $workspaceHtable.keys | where-object {$cwsps.workspaceId -match $_}
$mmawsps | Add-Member -type Noteproperty -Name PrimarySharedKey -Value $workspaceHtable.$match_key -Force
}
}

#If no workspaces, add Update Management Log Analytics Workspace
If($mmawsps.Length -lt "1")
{
Write-Output "There are no Workspaces, adding the default Log Analytics Workspace with Update Compliance"
Write-Host "Working on Workspace $UCworkspace"
$mma.AddCloudWorkspace($UCworkspaces[0],$UCworkspaces[1])
$mma.ReloadConfiguration()
}

#If 1 workspace or more remove those workspaces, add the Update Compliance Workspace, Re Add the workspaces
else
{
Write-Output "There are Multiple Workspaces"
Write-Output "Removing Current Workspaces and re-adding in correct order"

#Add workspaces
foreach ($workspace in $mmawsps) {
Write-Host "Working on Removing Workspace $workspace"
$mma.RemoveCloudWorkspace($workspace.workspaceId)
Write-Host "Reloading Config"
$mma.ReloadConfiguration()
Start-Sleep -Seconds 15
}

#Add Update Compliance Workspace
Write-Host "Adding the Update Management Workspace"
$mma.AddCloudWorkspace($UCworkspaces[0],$UCworkspaces[1])
$mma.ReloadConfiguration()
Start-Sleep -Seconds 15

#Readd Original WorkSpaces
foreach ($workspace in $mmawsps)
{
Write-Host "Working on Adding Workspace $workspace"
$mma.AddCloudWorkspace($workspace.workspaceId, $workspace.PrimarySharedKey)
Write-Host "Reloading Config"
$mma.ReloadConfiguration()
Start-Sleep -Seconds 15
}

#Finish
Write-Output "Configuration Complete"
}