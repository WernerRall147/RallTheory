<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230822
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>

param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext, 

[parameter(Mandatory=$false)]
[string]$DRResourceGroup = "#TODO Destination Resource group for alerts",

[parameter(Mandatory=$false)]
[string]$SubscriptionId = "#TODO Your Subscription ID",

[parameter(Mandatory=$false)]
[string]$WorkspaceName = "#TODO Your current log analytics workspace name",

[parameter(Mandatory=$false)]
[string]$actionGroup = "#TODO Your current actiongroup name",

[parameter(Mandatory=$false)]
[string]$targetRegion = "#TODO Your target region for alerts in short notation example: eastus"
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

Write-Output "Getting variables from Automation Account Store"
$DRResourceGroup = Get-AutomationVariable -Name 'DRResourceGroup'
$SubscriptionId = Get-AutomationVariable -Name 'SubscriptionId'
$WorkspaceName = Get-AutomationVariable -Name 'WorkspaceName'
$actionGroup = Get-AutomationVariable -Name 'actionGroup'
$targetRegion = Get-AutomationVariable -Name 'targetRegion'

#ResourceGraphQuery for all alerts per subscription. This will query the production subscription
Write-Output "Querying all alerts in the production subscription..."
$allAlerts = Search-AzGraph -Query ' 
resources
| where subscriptionId == "$SubscriptionId" and type in~ ("microsoft.insights/metricalerts","microsoft.insights/scheduledqueryrules") and ["kind"] !in~ ("LogToMetric","LogToApplicationInsights")
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
Write-Output "Cycling through alerts and creating them in the target subscription..."
try{
    foreach($rule in $allAlerts)
    {
        switch ($rule.type) {
            "microsoft.insights/metricalerts" {# Get the resource you want to monitor and Create the metric alert rule
              Write-Output "Working on metric alert rule: $($rule.name)" 
              Write-Output ($targetResource = $rule.properties.scopes | ConvertTo-Json -Depth 100 -Compress)
              Write-Output ($targetResourceformat = $targetResource -replace '"', '')
              Write-Output ($resource = Get-AzResource -ResourceId $targetResourceformat -ErrorAction Continue)
        
                # Define the condition for the alert
                #$condition = $rule.Properties.criteria | ConvertFrom-Json .................... $allAlerts.properties.criteria.allOf
                $condition = New-AzMetricAlertRuleV2Criteria -MetricName $rule.properties.criteria.allOf.metricName `
                -Operator $rule.properties.criteria.allOf.operator `
                -Threshold $rule.properties.criteria.allOf.threshold `
                -TimeAggregation $rule.properties.criteria.allOf.timeAggregation -ErrorAction Continue
        
                # Get the actiongroup
                Write-Output ($ActionGroupArray = Get-AzActionGroup | Where-Object {$_.Name -eq $actionGroup})
                Write-Output ($actG = Get-AzActionGroup -ResourceGroupName $ActionGroupArray.ResourceGroupName -Name $actionGroup -ErrorAction Continue )
        
                # Create the alert rule
                Write-Output (Add-AzMetricAlertRuleV2 -Name $rule.name -ResourceGroupName "$DRResourceGroup" -WindowSize 00:05:00 -Frequency 00:05:00 -TargetResourceId $resource.Id -Condition $condition -Severity $rule.Properties.severity -ActionGroupId $actG.Id -ErrorAction Continue)
            }

            "microsoft.insights/activitylogalerts" {#Get the resource you want to monitor and Create the activity log alerts
                 Write-Output "Working on activitylogalerts alert rule: $($rule.name)" 

                # Get the actiongroup
                Write-Output ($ActionGroupArray = Get-AzActionGroup | Where-Object {$_.Name -eq $actionGroup} -ErrorAction Continue)
                Write-Output ($actG = Get-AzActionGroup -ResourceGroupName $ActionGroupArray.ResourceGroupName -Name $actionGroup -ErrorAction Continue)
                $scope = "subscriptions/"+(Get-AzContext).Subscription.ID
                Write-Output ($actiongroupobj = New-AzActivityLogAlertActionGroupObject -Id $actG.Id -ErrorAction Continue)

                $conditionArray = @()
                foreach ($condition in $rule.properties.condition.allOf) {
                  Write-Output ($conditionObject = New-AzActivityLogAlertAlertRuleAnyOfOrLeafConditionObject -Equal $condition.equals -Field $condition.field -ErrorAction Continue)
                $conditionArray += $conditionObject
                }

                #Create the alert rule
                #New-AzActivityLogAlert -Name $AlertName -ResourceGroupName $DRResourceGroup -Action $actiongroupobj -Condition @($condition1,$condition2,$condition3) -Location global -Scope $scope
                #New-AzActivityLogAlert -Name $rule.Name -ResourceGroupName $DRResourceGroup -Action $actiongroupobj -Condition $rule.properties.condition.allOf -Location global -Scope $scope
                Write-Output (New-AzActivityLogAlert -Name $rule.Name -ResourceGroupName $DRResourceGroup -Action $actiongroupobj -Condition $conditionArray -Location global -Scope $scope -ErrorAction Continue)
            }

            "microsoft.insights/scheduledqueryrules" {#Get the resource you want to monitor and Create the scheduled query rules
              Write-Output "Working on scheduledqueryrules alert rule: $($rule.name)" 
                # Get the actiongroup
                Write-Output ($ActionGroupArray = Get-AzActionGroup | Where-Object {$_.Name -eq $actionGroup} -ErrorAction Continue)
                Write-Output ($actG = Get-AzActionGroup -ResourceGroupName $ActionGroupArray.ResourceGroupName -Name $actionGroup -ErrorAction Continue)
                Write-Output ($targetResource = $rule.properties.scopes | ConvertTo-Json -Depth 100 -Compress)
                Write-Output ($targetResourceformat = $targetResource -replace '"', '')
                Write-Output ($resource = Get-AzResource -ResourceId $targetResourceformat -ErrorAction Continue)

                # Create the Scheduled Query Rule
                $subscriptionId=(Get-AzContext).Subscription.Id
                Write-Output ($dimension = New-AzScheduledQueryRuleDimensionObject -Name Computer -Operator Include -Value *)

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
                -ResourceGroupName $DRResourceGroup `
                -Location $targetRegion `
                -DisplayName $rule.name `
                -Scope $resource.ResourceId `
                -Severity 4 `
                -WindowSize ([System.TimeSpan]::New(0,10,0)) `
                -EvaluationFrequency ([System.TimeSpan]::New(0,5,0)) `
                -CriterionAllOf $cond -ErrorAction Continue

            }

            "microsoft.alertsmanagement/smartdetectoralertrules"{#Get the resource you want to monitor and Create the smartdetector alert rules
              Write-Output "Working on smartdetectoralertrules alert rule: $($rule.name)" 

            #Get action groups
            Write-Output ($ActionGroupArray = Get-AzActionGroup | Where-Object {$_.Name -eq $actionGroup})
            Write-Output ($actG = Get-AzActionGroup -ResourceGroupName $ActionGroupArray.ResourceGroupName -Name $actionGroup -ErrorAction Continue)

            # Your Bicep file
            $schema = '$schema' 
            $smartdetectoralertrulesnameBVAR = $rule.name
            $actgidBVAR = $actG.Id
            $scopesBVAR = $rule.properties.scope
          
            $bicepFile = @"
            {
                "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "metadata": {
                },
                "parameters": {
                  "smartdetectoralertrulesname": {
                    "type": "string",
                    "defaultValue": "$smartdetectoralertrulesnameBVAR"
                  },
                  "actgid": {
                    "type": "string",
                    "defaultValue": "$actgidBVAR"
                  },
                  "scopes": {
                    "type": "string",
                    "defaultValue": "$scopesBVAR"
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
                      "severity": "Sev3",
                      "state": "enabled"
                    }
                  }
                ]
              }
"@
            # Write the Bicep file to disk
            Write-Output ($bicepFilePath = '.\smartdetectoralertrules.json')
            Write-Output (Set-Content -Path $bicepFilePath -Value $bicepFile -ErrorAction Continue)
            
            #Deploy using Bicep as there are no powershell modules available
            Write-Output (New-AzResourceGroupDeployment -ResourceGroupName $DRResourceGroup -TemplateFile .\smartdetectoralertrules.json -TemplateParameterObject $templateParams -Mode Incremental -ErrorAction Continue)
            
            }

            Default {Write-Output ""$rule.type"is not recognized and cannot be created"}
        }
    }
}catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

Write-Output "The script has completed with or without errors."