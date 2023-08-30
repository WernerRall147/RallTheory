<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230821
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>

param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext, 

[parameter(Mandatory=$false)]
[string]$DRResourceGroup = "#TODO Destination Resource group for alerts",

[parameter(Mandatory=$false)]
[string]$vmResourceId = "#TODO Your Virtual Machine ID for Insights",

[parameter(Mandatory=$false)]
[string]$WorkspaceResID = "#TODO Your current log analytics resource ID",

[parameter(Mandatory=$false)]
[string]$osType = "#TODO Your VM OS type, example: Windows",

[parameter(Mandatory=$false)]
[string]$targetRegion = "#TODO Your target region for alerts in short notation example: eastus"
)

Write-Output "Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."
#Log in with the Managed Identity
Write-Output "Logging in to Azure..."
try{
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

#Decyfer RecoveryPlan Context
Write-Output "Getting variables from Automation Account Store"
Write-output ($DRResourceGroup = Get-AutomationVariable -Name 'DRResourceGroup')
Write-output ($workspaceResId = Get-AutomationVariable -Name 'WorkspaceResId')
Write-output ($targetRegion = Get-AutomationVariable -Name 'targetRegion')

Write-Output "Getting Recovery Plan context"
$VMinfo = $RecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | Select-Object -ExpandProperty Name
$vmMap = $RecoveryPlanContext.VmMap

Write-Output "for Each VM trying to enable VMInsights on the VMs"
try{
foreach($VMID in $VMinfo)
{
    $VM = $vmMap.$VMID                
        if( !(($Null -eq $VM) -Or ($Null -eq $VM.ResourceGroupName) -Or ($Null -eq $VM.RoleName))) {
        #this check is to ensure that we skip when some data is not available else it will fail
        Write-output "The Resource group name ", $VM.ResourceGroupName
        Write-output "The current Server name is ", $VM.RoleName

$VMProps = Get-AzVM -Name $VM.RoleName
try {
    if ($VMProps.LicenseType -like "*Windows*") {
    
        Write-Output "The VM Resource ID is" $VMProps.Id
        Write-Output "The VM OS is" $VMProps.StorageProfile.ImageReference.Offer
        $osType = "Windows"
        
    }elseif ($VMProps.StorageProfile.ImageReference.Offer -notlike "*Windows*") {
        Write-Output "The VM Resource ID is" $VMProps.Id
        Write-Output "The VM OS is" $VMProps.StorageProfile.ImageReference.Offer
        $osType = "Linux"
    }else{
    Write-output "The VM OS could not be determined and this script choose the default OS which is Linux"
    $osType = "Linux"
    }
}
catch {
    Write-Output "There was an error retrieving OS Settings, the script will fail"
}


Write-Output($templateParams = @{
    VmResourceId = $VMProps.Id
    VmLocation = $targetRegion
    osType = $osType
    WorkspaceResourceId = $WorkspaceResID
})

$schema = '$schema'
$bicepFile = @"
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "metadata": {
      "_generator": {
        "name": "bicep",
        "version": "0.5.6.12127",
        "templateHash": "5890554597225741728"
      }
    },
    "parameters": {
      "VmResourceId": {
        "type": "string",
        "metadata": {
          "description": "VM Resource ID."
        }
      },
      "VmLocation": {
        "type": "string",
        "metadata": {
          "description": "The Virtual Machine Location."
        }
      },
      "osType": {
        "type": "string",
        "metadata": {
          "description": "OS Type, Example: Linux / Windows"
        }
      },
      "WorkspaceResourceId": {
        "type": "string",
        "metadata": {
          "description": "Workspace Resource ID."
        }
      }
    },
    "variables": {
      "VmName_var": "[split(parameters('VmResourceId'), '/')[8]]",
      "DaExtensionName": "[if(equals(toLower(parameters('osType')), 'windows'), 'DependencyAgentWindows', 'DependencyAgentLinux')]",
      "DaExtensionType": "[if(equals(toLower(parameters('osType')), 'windows'), 'DependencyAgentWindows', 'DependencyAgentLinux')]",
      "DaExtensionVersion": "9.5",
      "MmaExtensionName": "[if(equals(toLower(parameters('osType')), 'windows'), 'MMAExtension', 'OMSExtension')]",
      "MmaExtensionType": "[if(equals(toLower(parameters('osType')), 'windows'), 'MicrosoftMonitoringAgent', 'OmsAgentForLinux')]",
      "MmaExtensionVersion": "[if(equals(toLower(parameters('osType')), 'windows'), '1.0', '1.4')]"
    },
    "resources": [
      {
        "type": "Microsoft.Compute/virtualMachines",
        "apiVersion": "2021-11-01",
        "name": "[variables('VmName_var')]",
        "location": "[parameters('VmLocation')]"
      },
      {
        "type": "Microsoft.Compute/virtualMachines/extensions",
        "apiVersion": "2021-11-01",
        "name": "[format('{0}/{1}', variables('VmName_var'), variables('DaExtensionName'))]",
        "location": "[parameters('VmLocation')]",
        "properties": {
          "publisher": "Microsoft.Azure.Monitoring.DependencyAgent",
          "type": "[variables('DaExtensionType')]",
          "typeHandlerVersion": "[variables('DaExtensionVersion')]",
          "autoUpgradeMinorVersion": true
        },
        "dependsOn": [
          "[resourceId('Microsoft.Compute/virtualMachines', variables('VmName_var'))]"
        ]
      },
      {
        "type": "Microsoft.Compute/virtualMachines/extensions",
        "apiVersion": "2021-11-01",
        "name": "[format('{0}/{1}', variables('VmName_var'), variables('MmaExtensionName'))]",
        "location": "[parameters('VmLocation')]",
        "properties": {
          "publisher": "Microsoft.EnterpriseCloud.Monitoring",
          "type": "[variables('MmaExtensionType')]",
          "typeHandlerVersion": "[variables('MmaExtensionVersion')]",
          "autoUpgradeMinorVersion": true,
          "settings": {
            "workspaceId": "[reference(parameters('WorkspaceResourceId'), '2021-12-01-preview').customerId]",
            "azureResourceId": "[parameters('VmResourceId')]",
            "stopOnMultipleConnections": true
          },
          "protectedSettings": {
            "workspaceKey": "[listKeys(parameters('WorkspaceResourceId'), '2021-12-01-preview').primarySharedKey]"
          }
        },
        "dependsOn": [
          "[resourceId('Microsoft.Compute/virtualMachines', variables('VmName_var'))]"
        ]
      }
    ]
  }
"@
# Write the Bicep file to disk
$bicepFilePath = '.\enablevminsights.json'
Write-Output(Set-Content -Path $bicepFilePath -Value $bicepFile -ErrorAction Continue)

#Deploy using Bicep as there are no powershell modules available
Write-Output(New-AzResourceGroupDeployment -ResourceGroupName $DRResourceGroup -TemplateFile .\enablevminsights.json -TemplateParameterObject $templateParams -Mode Incremental)

}
else {
    Write-Error "Something went wrong when we tried to enable VMInsights on $VM"
}
}
}
catch {
Write-Error -Message $_.Exception
throw $_.Exception
}

