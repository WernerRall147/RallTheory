#The idea here is to export the resources of a resource group to a template file instead of using pwoershell cmdlets to do it.
param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext, 

[parameter(Mandatory=$false)]
[string]$SourceResourceGroup = "#TODO Source Resource group for alerts",

[parameter(Mandatory=$false)]
[string]$TargetResourceGroup = "#TODO Destination Resource group for alerts",

[parameter(Mandatory=$false)]
[string]$SourceSubscriptionId = "#TODO Your Source Subscription ID",

[parameter(Mandatory=$false)]
[string]$TargetSubscriptionId = "#TODO Your Destination Subscription ID",

[parameter(Mandatory=$false)]
[string]$targetRegion = "#TODO Your target region for alerts in short notation example: eastus"
)

#We will need to get the resurces using Resource Graph
#ResourceGraphQuery for all alerts per subscription. This will query the production subscription
Write-Output "Querying all resources"
$allResources = Search-AzGraph -Query 'resources'

#using the above we can export the templates for each resource group or resource
$ExportedARMTemplateExport = Export-AzResourceGroup -ResourceGroupName $allResources[90].resourceGroup -Resource $allResources[90].ResourceId -Confirm:$false
$ExportedARMTemplateExport | ConvertFrom-Json
