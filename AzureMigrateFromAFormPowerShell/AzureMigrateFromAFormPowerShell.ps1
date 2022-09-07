##Case
# We need to do Azure migration for on Premise Machine to Azure
#
## What input do I need
# Azure Migrate Project
# Servers 
# Server Readiness
# Destination
# Test Failover
# Test Failover Cleanup
# Complete Failover
#
## What steps do I need to take
# Select Correct Project
# Select Server
# View Server Readiness
# Choose Destination
# Complete Test Failover
# Cleanup Test Failover
# Complete Real Failover
#
## What is my outcome
# successfully kick off a migration from a form

#Requires -Module Az.Migrate

#Parameters
[CmdletBinding()]
param (
    [Parameter()]$azMigrateProjects,
    [Parameter()]$resourceGroupName,
    [Parameter()]$server = "",
    [Parameter()]$serverReadiness,
    [Parameter()]$destination,
    [Parameter()]$AppID = "",
    [Parameter()]$appSecret = "",
    [Parameter()]$tenant = ""
)

#Authentication with a Service Principal
function azureAuth {
#request AppID and Secret and create a secure Object
$Secret = ConvertTo-SecureString $appSecret -AsPlainText -Force

#Create Credential Object
$credObject = New-Object System.Management.Automation.PSCredential($AppId, $Secret)

# Use the application ID as the username, and the secret as password
Connect-AzAccount -ServicePrincipal -Credential $credObject -Tenant $tenant | Out-Null
}

#Select Server from Azure Migrate 
function FindAzMigrateServer {

    $azMigrateProjects = Search-AzGraph -Query '
    resources
    | where type == "microsoft.migrate/migrateprojects"
    '
    
foreach($proj in $azMigrateProjects){
   $chosenServ = Get-AzMigrateDiscoveredServer $server -SubscriptionId $proj.subscriptionId -ProjectName $proj.name -ResourceGroupName $proj.resourceGroup -DisplayName $server
 }   
}

#Check if Server is already replicating otherwise start replication
function assessAzChosenServReadiness {
    
    $serverReplication = Get-AzMigrateServerReplication -MachineName $chosenServ -SubscriptionId $proj.subscriptionId -ProjectName $proj.name -ResourceGroupName $proj.resourceGroup

    if ($serverReplication.MigrationState -eq "Replicating") {
        #Do Nothing
    }else {
        New-AzMigrateServerReplication -DiskType Standard_LRS -LicenseType WindowsServer -MachineId "" 
        -OSDiskID "" -TargetNetworkId "" -TargetResourceGroupId "" -TargetSubnetName "" -TargetVMName "" 
    }

}

#Start a Test Migration
function startTestMigration {
    $obj = Get-AzMigrateServerReplication -TargetObjectID $env.srsMachineId -SubscriptionId $env.srsSubscriptionId
    Start-AzMigrateTestMigration -InputObject $obj -TestNetworkId ""
}

#Clean up a successful Test Migration
function cleanupTestMigration {
    Start-AzMigrateTestMigrationCleanup -TargetObjectID ""

}

#Start the real production migration
function startMigration {
    Start-AzMigrateServerMigration -TargetObjectID ""
}






