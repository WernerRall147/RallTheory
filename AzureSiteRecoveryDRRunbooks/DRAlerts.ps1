<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: Oct 26, 2021
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
        Included variables in this context
        Variable name	            Description
        RecoveryPlanName	Recovery plan name. Used in actions based on the name.
        FailoverType	            Specifies whether it's a test or production failover.
        FailoverDirection	        Specifies whether recovery is to a primary or secondary location.
        GroupID	                        Identifies the group number in the recovery plan when the plan is running.
        VmMap	                       An array of all VMs in the group.
        VMMap key	                A unique key (GUID  ) for each VM.
        SubscriptionId	            The Azure subscription ID in which the VM was created.
        ResourceGroupName	Name of the resource group in which the VM is located.
        CloudServiceName	    The Azure cloud service name under which the VM was created.
        RoleName	                    The name of the Azure VM.
        RecoveryPointId	            The timestamp for the VM recovery.
#>

"Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."

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

Write-Host "Getting DR Resource Groups"
$AllRGs = "#TODO DR RSG"

    foreach($rg in $AllRGs){
        #For each IAM the RG until you find an email address for either Owner or Contributor
        $rContributors = Get-AzRoleAssignment -ResourceGroupName $rg -RoleDefinitionName 'Contributor' | where-object SignInName -NE $null | Select-Object SignInName | Sort-Object ResourceType -Unique
        $rOwners = Get-AzRoleAssignment -ResourceGroupName $rg -RoleDefinitionName 'Owner' | where-object SignInName -NE $null | Select-Object SignInName | Sort-Object ResourceType -Unique
        Write-Host "Search for Contributors in the " + $rg + " Resource Group"

         if ($rContributors.SignInName -ne $null) {
            Write-Host "Contributors Found in the Resource Group, building an Array"
            $contactemailadress = $rContributors.SignInName
         }
         elseif ($rOwners.SignInName -ne $null) {
            Write-Host "No Contributors found, looking for Owners"
            $contactemailadress = $rOwners.SignInName
            Write-Host "Owners Found in the Resource Group, building an Array"
         }else {
            Write-Host "No Valid Contributors or Owners found for $rg"
         }
        
        #(Needs to be idempotent) Create Service Health Alerts
        Write-Host "Generating some numbers"
        $randomnumber = Get-Random -Minimum 1000 -Maximum 9999
        $actionGroupName = $rg + "actionGroup" + $randomnumber
        $actionGroupShortName = "action" + $randomnumber
        $activityLogAlertName = "serviceHealthAlert" + $randomnumber

        #Create Health Alert Option 1
        foreach($ctact in $contactemailadress){
        Write-Host "Creating a Health Alert for $ctact"
        New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateUri https://raw.githubusercontent.com/WernerRall147/RallTheory/main/CreateServiceHealthAlertsForMyResources/ServiceHealthResourceGroupOnly.json `
        -actionGroupName $actionGroupName -actionGroupShortName $actionGroupShortName -activityLogAlertName $activityLogAlertName -emailAddress $ctact
        }
    
    $output = "Service Health Alerts have been created for your " + $_.Name + " subscription"
    $output   
 }
