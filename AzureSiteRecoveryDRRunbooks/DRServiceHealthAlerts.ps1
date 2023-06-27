<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230627
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>
param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext
)

Write-Output "Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

#Log in with the Managed Identity
try
{
  Write-Output "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}


#Decyfer RecoveryPlan Context
Write-Output "Getting Recovery Plan context"
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

Write-Output "Getting DR Resource Groups"
$AllRGs = $VM.ResourceGroupName

Write-Output "Cycle through the resource groups to find owners and contributors"
    foreach($rg in $AllRGs){
        #For each IAM the RG until you find an email address for either Owner or Contributor
        $rContributors = Get-AzRoleAssignment -ResourceGroupName $rg -RoleDefinitionName 'Contributor' | where-object SignInName -NE $null | Select-Object SignInName | Sort-Object ResourceType -Unique
        $rOwners = Get-AzRoleAssignment -ResourceGroupName $rg -RoleDefinitionName 'Owner' | where-object SignInName -NE $null | Select-Object SignInName | Sort-Object ResourceType -Unique
        Write-Output "Search for Contributors in the " + $rg + " Resource Group"

         if ($null -ne $rContributors.SignInName) {
            Write-Output "Contributors Found in the Resource Group, building an Array"
            $contactemailadress = $rContributors.SignInName
         }
         elseif ($null -ne $rOwners.SignInName) {
            Write-Output "No Contributors found, looking for Owners"
            $contactemailadress = $rOwners.SignInName
            Write-Output "Owners Found in the Resource Group, building an Array"
         }else {
            Write-Output "No Valid Contributors or Owners found for $rg"
         }
        
        #(Needs to be idempotent) Create Service Health Alerts
        Write-Output "Generating some numbers"
        $randomnumber = Get-Random -Minimum 1000 -Maximum 9999
        $actionGroupName = $rg + "actionGroup" + $randomnumber
        $actionGroupShortName = "action" + $randomnumber
        $activityLogAlertName = "serviceHealthAlert" + $randomnumber

         #Create a JSON file ARM Template to use for deployment can be found https://raw.githubusercontent.com/WernerRall147/RallTheory/main/CreateServiceHealthAlertsForMyResources/ServiceHealthResourceGroupOnly.json
         Write-Output "Generating ARM Template"
         $schema = '$schema'
         $templateFile = @"
         {
          "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
          "contentVersion": "1.0.0.0",
          "parameters": {
            "actionGroupName": {
              "type": "string",
              "defaultValue":  "serviceHealthActionGroup",
              "minLength": 1,
              "metadata": {
                "description": "Name for the Action group."
              }
            },
            "actionGroupShortName": {
              "type": "string",
              "defaultValue": "serviceAG",
              "minLength": 1,
              "maxLength": 12,
              "metadata": {
                "description": "Short name for the Action group."
              }
            },
            "emailAddress": {
              "type": "string",
              "metadata": {
                "description": "Email address."
              }
            },
            "activityLogAlertName": {
              "type": "string",
              "defaultValue": "serviceHealthAlert",
              "minLength": 1,
              "metadata": {
                "description": "Name for the Activity log alert."
              }
            },
            "rgName": {
              "type": "string",
              "defaultValue": "[resourceGroup().name]",
              "minLength": 1,
              "metadata": {
                "description": "Resource Group Scope for the Activity Logs ."
              }
            },
            "subName": {
              "type": "string",
              "defaultValue": "[subscription().subscriptionId]",
              "minLength": 1,
              "metadata": {
                "description": "Resource Group Scope for the Activity Logs ."
              }
            }
          },
          "resources": [
            {
              "type": "Microsoft.Insights/actionGroups",
              "apiVersion": "2019-06-01",
              "name": "[parameters('actionGroupName')]",
              "location": "Global",
              "properties": {
                "groupShortName": "[parameters('actionGroupShortName')]",
                "enabled": true,
                "emailReceivers": [
                  {
                    "name": "emailReceiver",
                    "emailAddress": "[parameters('emailAddress')]"
                  }
                ]
              }
            },
            {
              "type": "Microsoft.Insights/activityLogAlerts",
              "apiVersion": "2020-10-01",
              "name": "[parameters('activityLogAlertName')]",
              "location": "Global",
              "dependsOn": [
                "[parameters('actionGroupName')]"
              ],
              "properties": {
                "enabled": true,
                "scopes": [
                  "[concat('/subscriptions/',uriComponent(parameters('subName')),'/resourcegroups/',uriComponent(parameters('rgName')))]"
                ],
                "condition": {
                  "allOf": [
                    {
                      "field": "category",
                      "equals": "ServiceHealth"
                    }
                  ]
                },
                "actions": {
                  "actionGroups": [
                    {
                      "actionGroupId": "[resourceId('Microsoft.Insights/actionGroups', parameters('actionGroupName'))]"
                    }
                  ]
                }
              }
            }
          ]
        }
"@
         $templatefile_path = "$env:SystemDrive\temp\Deploy.json"
         $templateFile | Out-File -FilePath $templatefile_path

        #Create Health Alert Option 1
        foreach($ctact in $contactemailadress){
        Write-Output "Creating a Health Alert for $ctact"
        New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateFile $templatefile_path  `
        -actionGroupName $actionGroupName -actionGroupShortName $actionGroupShortName `
        -activityLogAlertName $activityLogAlertName -emailAddress $ctact
        }
    
    $output = "Service Health Alerts have been created for your " + $_.Name + " subscription"
    $output   
 }

 Write-Output "The script has completed with or without errors."
