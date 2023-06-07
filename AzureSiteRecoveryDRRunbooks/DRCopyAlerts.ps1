<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230607
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

#"Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."
#Log in with the Managed Identity
try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

$thisSub = (Get-AzContext).Subscription.Id

#ResourceGraphQuery for all alerts per subscription. This will query the production subscription
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


try{
foreach($rule in $allAlerts)
{
if ($rule.type -eq "microsoft.insights/metricalerts") 
     {
        # Get the resource you want to monitor and Create the metric alert rule
        $resource = Get-AzResource -ResourceGroupName $destResourceGroup -Name #TODO

        # Define the condition for the alert
        #$condition = $rule.Properties.criteria | ConvertFrom-Json .................... $allAlerts.properties.criteria.allOf
        $condition = New-AzMetricAlertRuleV2Criteria -MetricName $rule.properties.criteria.allOf.metricName `
        -Operator $rule.properties.criteria.allOf.operator -Threshold $rule.properties.criteria.allOf.threshold `
        -TimeAggregation $rule.properties.criteria.allOf.timeAggregation

        # Get the actiongroup
        $ActionGroupArray = Get-AzActionGroup | Where-Object {$_.Name -eq $actionGroup}
        $actG = Get-AzActionGroup -ResourceGroupName $ActionGroupArray.ResourceGroupName -Name $actionGroup  

        # Create the alert rule
        Add-AzMetricAlertRuleV2 -Name $rule.name -ResourceGroupName "$destResourceGroup" -WindowSize 00:05:00 `
        -Frequency 00:05:00 -TargetResourceId $resource.Id -Condition $condition -Severity $rule.Properties.severity `
        -ActionGroupId $actG.Id 


} elseif ($rule.type -eq "microsoft.insights/activitylogalerts") {
    Write-Output "This is an Activity Log Alert: $rule.Name"

    




} else {
Write-Output "$rule.type is not supported. This script only supports microsoft.insights/metricalerts and microsoft.insights/activitylogalerts"
}
}
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}


