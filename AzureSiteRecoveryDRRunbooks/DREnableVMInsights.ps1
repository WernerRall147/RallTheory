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

#Get all ARM resources from all resource groups
$DestinationResourceGroup = Get-AZResourcegroup -Name "#TODO"
$DestinationResources = Get-AZResource -ResourceGroupName $DestinationResourceGroup

# Ensure insights get enabled
#Install-Script -Name Install-VMInsights
foreach($drres in $DestinationResources){
    $WorkspaceId = "#TODO"
    $WorkspaceKey = "#TODO"
    .\Install-VMInsights.ps1 -WorkspaceId $WorkspaceId -WorkspaceKey $WorkspaceKey -SubscriptionId SubscriptionId -WorkspaceRegion ($DestinationResourceGroup).Location
    }
