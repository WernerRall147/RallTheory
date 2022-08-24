#Log in to Azure account
Connect-AzAccount

#Get list of Azure Subscription ID's
$Subs = get-AzSubscription

#Loop through the subscriptions to find all Resource Groups and create the Service Health Alerts
$Subs | ForEach-Object -Parallel {
    Set-AzContext -SubscriptionId $_.Id
    $AllRGs = (Get-AzResourceGroup).ResourceGroupName
    foreach($rg in $AllRGs){
        #For each member of the Contributor group
        $rContributors = Get-AzRoleAssignment -ResourceGroupName $rg -RoleDefinitionName Contributor
        
        #Look for specific resource types in each Resource Group
        #$rTypes = Get-AzResource -ResourceGroupName $rg | Select-Object ResourceType | Sort-Object ResourceType -Unique

        #Create Service Health Alerts
        $randomnumber = Get-Random -Minimum 1000 -Maximum 9999
        $actionGroupName = $rg + "actionGroup" + $randomnumber
        $actionGroupShortName = "actionGroup" + $randomnumber
        $activityLogAlertName = "serviceHealthAlert"

        #Create Health Alert Option 1
        New-AzResourceGroupDeployment -ResourceGroupName "RLY-mgmt" -TemplateUri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/demos/monitor-servicehealth-alert/azuredeploy.json `
         -actionGroupName $actionGroupName -actionGroupShortName $actionGroupShortName -activityLogAlertName $activityLogAlertName 
        
        <#Create Health Alert Option 2
        $location = 'Global'
        $alertName = 'myAlert'
        $resourceGroupName = $rg
        $condition1 = New-AzActivityLogAlertCondition -Field 'field1' -Equal 'equals1'
        $condition2 = New-AzActivityLogAlertCondition -Field 'field2' -Equal 'equals2'
        $dict = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.String]"
        $dict.Add('key1', 'value1')
        $actionGrp1 = New-AzActionGroup -ActionGroupId 'actiongr1' -WebhookProperty $dict
        Set-AzActivityLogAlert -Location $location -Name $alertName -ResourceGroupName $resourceGroupName -Scope 'scope1','scope2' -Action $actionGrp1 -Condition $condition1, $condition2
            #>
        }
    
    $output = "Service Health Alerts have been created for " + $_.Name + "is your subscription"
    $output   
}

#Look for specific resource types in each Resource Group
#Foe each resource type found, set up a Resource Health Alert
#For each member of the Contributor group that has access to that Resource Group, convert elevated user to usable email address
#Add email addresses to action group for that health alert.
