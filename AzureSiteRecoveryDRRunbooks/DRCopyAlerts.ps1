<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230621
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>

param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext, 

[parameter(Mandatory=$false)]
[string]$destResourceGroup = "#TODO Destination Resource group for alerts",

[parameter(Mandatory=$false)]
[string]$SubscriptionId = "#TODO Your Subscription ID",

[parameter(Mandatory=$false)]
[string]$laworkspace = "#TODO Your current log analytics workspace name",

[parameter(Mandatory=$false)]
[string]$actionGroup = "#TODO Your current actiongroup name",

[parameter(Mandatory=$false)] `
[ValidateSet(
    "Australia East", "australiaeast",
    "Australia Central", "australiacentral",
    "Australia Central 2", "australiacentral2",
    "Australia Southeast", "australiasoutheast",
    "Brazil South", "brazilsouth",
    "Brazil Southeast", "brazilsoutheast",
    "Canada Central", "canadacentral",
    "Central India", "centralindia",
    "Central US", "centralus",
    "East Asia", "eastasia",
    "East US", "eastus",
    "East US 2", "eastus2",
    "East US 2 EUAP", "eastus2euap",
    "France Central", "francecentral",
    "France South", "francesouth",
    "Germany West Central", "germanywestcentral",
    "India South", "indiasouth",
    "Japan East", "japaneast",
    "Japan West", "japanwest",
    "Korea Central", "koreacentral",
    "North Central US", "northcentralus",
    "North Europe", "northeurope",
    "Norway East", "norwayeast",
    "Norway West", "norwaywest",
    "South Africa North", "southafricanorth",
    "Southeast Asia", "southeastasia",
    "South Central US", "southcentralus",
    "Switzerland North", "switzerlandnorth",
    "Switzerland West", "switzerlandwest",
    "UAE Central", "uaecentral",
    "UAE North", "uaenorth",
    "UK South", "uksouth",
    "West Central US", "westcentralus",
    "West Europe", "westeurope",
    "West US", "westus",
    "West US 2", "westus2",
    "USGov Arizona", "usgovarizona",
    "USGov Virginia", "usgovvirginia"
)]
[string]$targetRegion = "#TODO Your target region for alerts in short notation"
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

$thisSub = (Get-AzContext).Subscription.Id

#ResourceGraphQuery for all alerts per subscription. This will query the production subscription
Write-Output "Querying all alerts in the production subscription..."
$allAlerts = Search-AzGraph -Query ' 
resources
| where type in~ ("microsoft.insights/metricalerts","microsoft.insights/scheduledqueryrules") and ["kind"] !in~ ("LogToMetric","LogToApplicationInsights")
| extend severity = strcat("Sev", properties["severity"])
| extend enabled = tobool(properties["enabled"])
| where enabled in~ ("true")
| project id,name,type,properties,enabled,severity,subscriptionId
| union (resources | where type =~ "microsoft.alertsmanagement/smartdetectoralertrules" | extend severity = tostring(properties["severity"])
| extend enabled = properties["state"] =~ "Enabled" | where enabled in~ ("true") | project id,name,type,properties,enabled,severity,subscriptionId), (resources | where type =~ "microsoft.insights/activitylogalerts" | extend severity = "Sev4"
| extend enabled = tobool(properties["enabled"]) | mvexpand innerCondition = properties["condition"]["allOf"] | where innerCondition["field"] =~ "category"
| where enabled in~ ("true") | project id,name,type,properties,enabled,severity,subscriptionId)
| order by tolower(name) asc'

$ErrorActionPreference = 'Continue'

try{
    foreach($rule in $allAlerts)
    {
        switch ($rule.type) {
            "microsoft.insights/metricalerts" {# Get the resource you want to monitor and Create the metric alert rule
                $targetResource = $rule.properties.scopes | ConvertTo-Json -Depth 100 -Compress
                $resource = Get-AzResource -ResourceId $targetResource -ErrorAction Continue
                #$resource = Get-AzResource -ResourceGroupName $destResourceGroup -Name $targetResource
        
                # Define the condition for the alert
                #$condition = $rule.Properties.criteria | ConvertFrom-Json .................... $allAlerts.properties.criteria.allOf
                $condition = New-AzMetricAlertRuleV2Criteria -MetricName $rule.properties.criteria.allOf.metricName `
                -Operator $rule.properties.criteria.allOf.operator `
                -Threshold $rule.properties.criteria.allOf.threshold `
                -TimeAggregation $rule.properties.criteria.allOf.timeAggregation -ErrorAction Continue
        
                # Get the actiongroup
                $ActionGroupArray = Get-AzActionGroup | Where-Object {$_.Name -eq $actionGroup}
                $actG = Get-AzActionGroup -ResourceGroupName $ActionGroupArray.ResourceGroupName -Name $actionGroup -ErrorAction Continue 
        
                # Create the alert rule
                Add-AzMetricAlertRuleV2 -Name $rule.name -ResourceGroupName "$destResourceGroup" -WindowSize 00:05:00 `
                -Frequency 00:05:00 -TargetResourceId $resource.Id -Condition $condition -Severity $rule.Properties.severity `
                -ActionGroupId $actG.Id -ErrorAction Continue
            }

            "microsoft.insights/activitylogalerts" {#Get the resource you want to monitor and Create the activity log alerts

                # Get the actiongroup
                $ActionGroupArray = Get-AzActionGroup | Where-Object {$_.Name -eq $actionGroup} -ErrorAction Continue
                $actG = Get-AzActionGroup -ResourceGroupName $ActionGroupArray.ResourceGroupName -Name $actionGroup -ErrorAction Continue
                $scope = "subscriptions/"+(Get-AzContext).Subscription.ID
                $actiongroupobj = New-AzActivityLogAlertActionGroupObject -Id $actG.Id -ErrorAction Continue

                $conditionArray = @()
                foreach ($condition in $rule.properties.condition.allOf) {
                $conditionObject = New-AzActivityLogAlertAlertRuleAnyOfOrLeafConditionObject -Equal $condition.equals -Field $condition.field -ErrorAction Continue
                $conditionArray += $conditionObject
                }

                #Create the alert rule
                #New-AzActivityLogAlert -Name $AlertName -ResourceGroupName $destResourceGroup -Action $actiongroupobj -Condition @($condition1,$condition2,$condition3) -Location global -Scope $scope
                #New-AzActivityLogAlert -Name $rule.Name -ResourceGroupName $destResourceGroup -Action $actiongroupobj -Condition $rule.properties.condition.allOf -Location global -Scope $scope
                New-AzActivityLogAlert -Name $rule.Name -ResourceGroupName $destResourceGroup -Action $actiongroupobj -Condition $conditionArray -Location global -Scope $scope -ErrorAction Continue      
            }

            "microsoft.insights/scheduledqueryrules" {#Get the resource you want to monitor and Create the scheduled query rules
              
                # Get the actiongroup
                $ActionGroupArray = Get-AzActionGroup | Where-Object {$_.Name -eq $actionGroup} -ErrorAction Continue
                $actG = Get-AzActionGroup -ResourceGroupName $ActionGroupArray.ResourceGroupName -Name $actionGroup -ErrorAction Continue
                $targetResource = $rule.properties.scopes
                $resource = Get-AzResource -TargetResourceId $targetResource -ErrorAction Continue

                # Create the Scheduled Query Rule
                $subscriptionId=(Get-AzContext).Subscription.Id
                $dimension = New-AzScheduledQueryRuleDimensionObject -Name Computer `
                -Operator Include -Value *

                $cond = New-AzScheduledQueryRuleConditionObject -Dimension $dimension `
                 -Query "Perf | where ObjectName == `"Processor`" and CounterName == `"% Processor Time`" | summarize AggregatedValue = avg(CounterValue) by bin(TimeGenerated, 5m), Computer" `
                 -TimeAggregation "Average" `
                 -MetricMeasureColumn "AggregatedValue" `
                 -Operator "GreaterThan" `
                 -Threshold "70" `
                 -FailingPeriodNumberOfEvaluationPeriod 1 `
                 -FailingPeriodMinFailingPeriodsToAlert 1 -ErrorAction Continue
                
                New-AzScheduledQueryRule `
                -Name $rule.Name `
                -ResourceGroupName $destResourceGroup `
                -Location $targetRegion `
                -DisplayName $rule.name `
                -Scope $resource `
                -Severity 4 `
                -WindowSize ([System.TimeSpan]::New(0,10,0)) `
                -EvaluationFrequency ([System.TimeSpan]::New(0,5,0)) `
                -CriterionAllOf $cond -ErrorAction Continue

            }

            "microsoft.alertsmanagement/smartdetectoralertrules"{#Get the resource you want to monitor and Create the smartdetector alert rules
            
            #Get action groups
            $ActionGroupArray = Get-AzActionGroup | Where-Object {$_.Name -eq $actionGroup}
            $actG = Get-AzActionGroup -ResourceGroupName $ActionGroupArray.ResourceGroupName -Name $actionGroup -ErrorAction Continue

            #Generate Bicep template for Smart Detector Alert Rules
            # Your Bicep file
            $schema = '$schema' 
            $bicepFile = @"
            {
                "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "metadata": {
                },
                "parameters": {
                  "smartdetectoralertrulesname": {
                    "type": "string",
                    "defaultValue": "$rule.name"
                  },
                  "actgid": {
                    "type": "string",
                    "defaultValue": "$actG.Id"
                  },
                  "scopes": {
                    "type": "string",
                    "defaultValue": "$rule.properties.scope"
                  }
                },
                "resources": [
                  {
                    "type": "microsoft.alertsManagement/smartDetectorAlertRules",
                    "apiVersion": "2021-04-01",
                    "name": "[parameters('smartdetectoralertrulesname')]",
                    "location": "global",
                    "properties": {
                      "actionGroups": {
                        "groupIds": [
                          "[parameters('actgid')]"
                        ]
                      },
                      "description": "name",
                      "detector": {
                        "id": "FailureAnomaliesDetector",
                        "parameters": {}
                      },
                      "frequency": "PT1M",
                      "scope": [
                        "[parameters('scopes')]"
                      ],
                      "severity": "3",
                      "state": "enabled"
                    }
                  }
                ]
              }
"@
            # Write the Bicep file to disk
            $bicepFilePath = '.\smartdetectoralertrules.json'
            Set-Content -Path $bicepFilePath -Value $bicepFile -ErrorAction Continue
            
            #Deploy using Bicep as there are no powershell modules available
            New-AzResourceGroupDeployment -ResourceGroupName $destResourceGroup -TemplateFile .\smartdetectoralertrules.json -ErrorAction Continue 
            
            }

            Default {Write-Output ""$rule.type"is not recognized and cannot be created"}
        }
    }
}catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

