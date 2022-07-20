#add this to Pipeline YAML file
<#
- job: PowerShell
displayName: PowerShell
pool:
  vmImage: ubuntu-latest
steps:
- checkout: self
- task: AzurePowerShell@5
  inputs:
    azureSubscription: AzureDevOpsIaCpvtTF
    scriptType: filePath
    scriptPath: $(Build.SourcesDirectory)\PowerShell.ps1
    azurePowerShellVersion: latestVersion
    pwsh: true
#>

# Used in the process of moving Virtual Machines from one VNET to Another VNET

#Set some parameters
$resourceGroupName = '<RG Name>' 
$location = '<Location>' 
$vmName = '<VMName>'

#Get the VM
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

#Remove the Virtual Machine
$vm | Remove-AzVM -Force


