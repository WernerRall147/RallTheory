# A few tasks you might want to run during an Azure Site Recovery DR Scenario

# Pre Requisites
To complete a DR with Azure Site Recovery we need like-for-like resources in Primary and Failover Regions
For the below scripts to work with a Recovery Plan we need the below resources in our Failover region
1. Log Analytics Workspace
1. Azure Automation Account with Managed Identity that has contributor access in Primary and Failover Region
1. Storage Account for Diagnostic settings
1. Destination NSG attached to the Failover region Virtual Network Subnet
1. Add Az.AlertsManagement module to AutomationAccount
1. Add Az.Accounts module 2.12.3 or higher to AutomationAccount
1. Add Az.ResourceGraph module to AutomationAccount
1. Add Az.Monitor  module to AutomationAccount
1. [Recommended] Run the [createAutomationAccountVariables](createAutomationAccountVariables.ps1) script locally to automatically create the required variables in your automation account

# Using the runbooks
Import all the below runbooks into your Failover Region Automation Account and update all the variables labeled #TODO (Important: If you completed step 9 you can skip the #TODO Updates)
Some runbooks can be used inside the Recovery Plan but some has to be run outside the recovery plan as helper scripts. 

# DRNSGSync runbook is so that your source NSG Rules sync with the Destination NSG Rules
1. Check inbound port rules if NSGs are on Vnets - Run this runbook seperately

# DRCopyAlerts runbook is so that your source Alert rules sync with your Destination 
2. Copy and Create Custom/User created Alerts for DR Resource Group -Run this runbook seperately

# These Runbooks can be added to the Recovery Plan
1.  Ensure Diagnostics Settings are enabled - Run in recovery Plan
2.  Ensure Backup gets enabled - Run in Recovery Plan
3.  Ensure Insights get enabled - Run in Recovery Plan
4.  Create Service Health Alerts for DR Resource Group - Run in Recovery Plan

Please replace all the #TODO  in the scripts with your required variables (Important: If you completed step 9 in Pre Requisites you can skip the #TODO Updates)

---------------------------------------------------------------------------------------------
# Script Descriptions and Manual Alternatives

## [DRBackup](/AzureSiteRecoveryDRRunbooks/DRBackup.ps1)

This PowerShell script performs tasks that might be used in an Azure Site Recovery Disaster Recovery (DR) scenario. Azure Site Recovery allows your organization to have a disaster recovery plan in place for your Azure resources. This script is designed to be used as part of an Azure Automation Runbook, a collection of routine tasks that are run as needed or on a schedule.

Here's a high-level overview of what this script does:

1. Connects to Azure using Connect-AzAccount -Identity: This connects to Azure using the identity of the account running the script. This is usually run from an Azure automation account which has been given permissions to manage resources.

1. Decrypts the Recovery Plan Context: The script uses the $RecoveryPlanContext parameter to access information about the recovery plan, including virtual machine (VM) maps. These VM maps are essential in a recovery scenario as they help to understand the connections and dependencies between VMs.

1. For each VM in the recovery plan context, the script does the following:

1. Writes the resource group name and server name to the console.

1. Ensures backup is enabled for each VM in the plan. 

It does this by first retrieving the recovery services vault for the VM's resource group, then setting the vault context with Set-AzRecoveryServicesVaultContext. The backup protection policy named "DefaultPolicy" is then retrieved. Finally, Enable-AzRecoveryServicesBackupProtection is called to enable backup protection for the VM according to the retrieved policy. Note that the -WhatIf parameter is used, which means that the command will not actually run, but will instead display what would happen if the command were to run.
If any exceptions occur during the execution of the script, these are caught and the error message is displayed to the console. This helps with troubleshooting if anything goes wrong.

Remember to replace -WhatIf with actual execution command when you're ready to execute the script in production.

> **_NOTE:_**  As this is for DR Scenarios there may be alternative solutions we can use. If you would like to enable an Azure Policy to achieve the above please find a link to the Built-In Policy below. 

## [Back up Vm using Azure Policy](https://learn.microsoft.com/en-us/azure/backup/backup-azure-auto-enable-backup)

> **_NOTE:_**  As this is for DR Scenarios we need to also ensure the manual steps are included below. If your script does not complete successfully and you need to manually achieve DRBackup please follow the below link. 

## [Manually Back Up VM Using the Portal](https://learn.microsoft.com/en-us/azure/backup/quick-backup-vm-portal)


---------------------------------------------------------------------------------------------

## [DRCopyAlerts](/AzureSiteRecoveryDRRunbooks/DRCopyAlerts.ps1)

This PowerShell script appears to be part of a larger automation framework for managing Azure Site Recovery, a disaster recovery service by Microsoft Azure. It's designed to automate various disaster recovery (DR) tasks. Here's a breakdown of what it does:

1. Parameters: The script takes in a variety of parameters, some of which include the recovery plan context, destination resource group for alerts, subscription ID, log analytics workspace name, action group name, and target region for alerts. These parameters help specify the context and resources it needs to operate on.

1. Login: The script logs into Azure using a Managed Identity with the Connect-AzAccount -Identity command.

1. Querying Azure Resource Graph: Using Search-AzGraph command, it fetches all enabled alerts from the current subscription. The query looks for metric alerts, scheduled query rules, activity log alerts, and smart detector alert rules.

1. Loop over alerts: The script then enters a loop where it iterates over each alert rule it found in the Resource Graph query.

For metric alert rules (microsoft.insights/metricalerts), it replicates the existing alert in the destination resource group with the same name, condition, and severity. The alert's action group is set as specified by the user.

For activity log alerts (microsoft.insights/activitylogalerts), the script again replicates these to the destination resource group, but with different conditions.

For scheduled query rules (microsoft.insights/scheduledqueryrules), the script creates a new scheduled query rule in the destination resource group.

For smart detector alert rules (microsoft.alertsmanagement/smartdetectoralertrules), it uses a Bicep template to create a new smart detector alert rule. This process includes writing a JSON file that represents the Bicep template, and then deploying the template.

1. The script then catches any exceptions that occur during the processing of the alerts, writes the exception message to the error output, and re-throws the exception to stop execution.

Overall, the purpose of the script is to replicate Azure alert rules from one context (e.g., a production environment) to another (e.g., a disaster recovery environment). This helps ensure that alerts are monitored consistently across both environments, enhancing disaster recovery procedures.

> **_NOTE:_**  As this is for DR Scenarios we need to also ensure the manual steps are included below. If your script does not complete successfully and you need to manually achieve DRCopyAlerts please follow the below link..

## [Create or edit an alert rule in the Azure portal](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-create-new-alert-rule?tabs=metric)

---------------------------------------------------------------------------------------------

## [DRDiagnostics](/AzureSiteRecoveryDRRunbooks/DRDiagnostics.ps1)

This PowerShell script automates the setup of Azure Site Recovery (ASR) for a Disaster Recovery (DR) scenario. It operates on virtual machines (VMs) within a specific Azure Resource Group.

Below are the key functionalities of the script:

1. Logging In: The script logs into Azure using Managed Identity. It uses the Connect-AzAccount -Identity cmdlet to authenticate to Azure.

1. Decipher Recovery Plan Context: The script checks the Recovery Plan Context (an object passed as a parameter) and extracts VM information. It then iterates over the VM IDs and writes the associated resource group name to the output.

1. Diagnostics Configuration File: The script creates a default Diagnostics Configuration file (in JSON format) which contains various metrics, logs, and counters that are needed for diagnostics.

1. ARM Resources From DR: The script retrieves the Azure Resource Manager (ARM) resources associated with the disaster recovery site. These resources are assumed to be associated with the VM's resource group that was previously obtained from the Recovery Plan Context.

1. Diagnostics Settings: It checks whether each VM in the Disaster Recovery (DR) site has Diagnostics Settings enabled. If not, it updates the placeholders in the Diagnostics Configuration file with the specific resource ID, storage account name, and storage account key. It then sets the Diagnostics Settings using the updated Diagnostics Configuration file.

The script can throw errors in situations such as when it can't authenticate to Azure, when it can't retrieve VM information, or when it can't set the Diagnostics Settings. Any exceptions are caught and their messages are written to the output.

> **_NOTE:_**  As this is for DR Scenarios there may be alternative solutions we can use. If you would like to enable an Azure Policy to achieve the above please find a link to the Built-In Policy below. 

## [Create diagnostic settings at scale using Azure Policies and Initiatives](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings-policy)

> **_NOTE:_**  As this is for DR Scenarios we need to also ensure the manual steps are included below. If your script does not complete successfully and you need to manually achieve DRDiagnostics please follow the below link.

## [Install and configure the Azure Diagnostics extension for Windows in the Azure portal](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/diagnostics-extension-windows-install)

---------------------------------------------------------------------------------------------
## [DRNSGSync](/AzureSiteRecoveryDRRunbooks/DRNSGSync.ps1)

The PowerShell script provided here is designed to help manage network security during an Azure Site Recovery Disaster Recovery (DR) scenario.

Azure Site Recovery enables the replication, failover, and recovery of workloads, so that they remain available during outages. Network security is a key part of ensuring the resiliency of these systems.

Here's a breakdown of what this PowerShell script does:

1. The script first checks if a parameter $RecoveryPlanContext is provided. This is not mandatory.

1. Then, it prints a message suggesting the user to enable the appropriate RBAC (Role-Based Access Control) permissions for the system identity of this automation account.

1. It then attempts to log in to Azure using Managed Identity. If the login fails, it writes the error message to the console and re-throws the exception.

1. It retrieves two Azure Resource Groups, labeled as "Source" and "Destination". The names of these Resource Groups are placeholders ("#TODO") which need to be replaced by actual names before the script is run.

1. It also gets the Network Security Groups (NSGs) for the source and destination networks. These are also placeholders that need to be filled in.

1. The script then retrieves the Security Rules for both NSGs.

1. It then compares the Security Rules between the Source NSG and the Destination NSG.

1. If the rules match, it prints "The rules match".

1. If the rules don't match, it prints "The rules do not match, trying to repair". The script then goes through each security rule in the source NSG, retrieves the destination NSG, and adds the source security rule to the destination NSG, effectively making the destination NSG's rules match the source's.

1. If there are any issues during this process, it catches the exception and prints the error message to the console.

The main purpose of this script is to ensure that network security settings (specifically, security rules) are consistent between two different resource groups within an Azure environment, particularly for disaster recovery scenarios. This is helpful to ensure the DR site has the same security settings as the original site to maintain network security and compliance.

> **_NOTE:_**  As this is for DR Scenarios we need to also ensure the manual steps are included below. If your script does not complete successfully and you need to manually achieve DRNSGSync please follow the below link.

## [Create, change, or delete a network security group in the Azure portal](https://learn.microsoft.com/en-us/azure/virtual-network/manage-network-security-group?tabs=network-security-group-portal)

---------------------------------------------------------------------------------------------
## [DRReprotectVMs](/AzureSiteRecoveryDRRunbooks/DRReprotectVMs.ps1)

The provided script is designed for Azure Site Recovery (ASR) during a disaster recovery scenario. It is an automation script for enabling re-protection and replication of virtual machines (VMs) in Azure after a disaster recovery event.

Here's the breakdown of the script:

1. Parameters: The script accepts three optional parameters:

RecoveryPlanContext: a recovery plan context object which includes information about the virtual machines to be recovered.
recoveryservicesname: the name of the recovery services vault. This is where your data and backups are stored.
fabricName: the name of the fabric. Fabric in Azure Site Recovery is a logical construct that holds the compute and network resources of a datacenter.
1. Permissions: It reminds the user to set appropriate RBAC permissions for the system identity of this automation account to avoid failure.

1. Login: It logs into Azure using Managed Identity. If the login fails, it throws an exception.

1. VM Information: It deciphers recovery plan context to get information about VMs. VMinfo and vmMap variables hold this information.

1. Re-Protection and Replication: The script then loops over each VM in the recovery plan context and checks if the required information is available. If yes, it gets the recovery services vault and sets it as the current context.

It retrieves the Azure Site Recovery (ASR) Fabric and Protection Container based on the provided fabric name, and the Replication Protected Item (which represents the VM in the protection infrastructure).

It then starts reprotecting the VM, which means it enables replication back from the target site (where you failed over to) to the source site (where you failed over from). This is useful to ensure your original location gets updated with any changes that happened at the disaster recovery site after a failover, preparing it to be a viable disaster recovery site again in case of another disaster.

1. Error Handling: If any of the steps within the loop fails, it prints an error message and throws an exception.

So, in summary, this script is used in the context of disaster recovery to re-enable protection and replication for each virtual machine in a recovery plan after a failover has occurred. This prepares the system to handle another potential disaster.

> **_NOTE:_**  As this is for DR Scenarios we need to also ensure the manual steps are included below. If your script does not complete successfully and you need to manually achieve DRReprotectVMs please follow the below link.

## [Reprotect failed over Azure VMs to the primary region in the Azure portal](https://learn.microsoft.com/en-us/azure/site-recovery/azure-to-azure-how-to-reprotect)

---------------------------------------------------------------------------------------------

## [DRServiceHealthAlerts](/AzureSiteRecoveryDRRunbooks/DRServiceHealthAlerts.ps1)

This PowerShell script performs several tasks related to Azure Site Recovery (ASR) during a disaster recovery scenario. Here is a summary of its activities:

1. Permissions Reminder: The script reminds the user to set appropriate RBAC permissions for the system identity of this automation account.

1. Azure Login: The script logs into Azure using a Managed Identity. If login fails, it throws an exception.

1. Decyphering Recovery Plan Context: The script then extracts VM information from the provided recovery plan context. The variables VMinfo and vmMap hold this information.

1. Identify Resource Groups: The script then gets all the resource groups from the recovery plan context.

1. Identify Role Assignment: For each resource group, the script retrieves the Azure role assignments, identifying the contributors and owners. If it finds contributors or owners, it stores their email addresses.

1. Service Health Alerts: The script generates unique names for action groups and activity log alerts by creating random numbers. It then constructs an ARM (Azure Resource Manager) JSON template for the service health alerts and writes it to a file.

This template will create an action group with an email receiver (the contributor or owner email address found before), and an activity log alert that fires whenever a "ServiceHealth" event happens. This alert is scoped to the resource group and associated with the created action group.

1. Deploy the Health Alert: For each email address found in the previous steps, the script deploys the created ARM template to create the service health alert for that email address.

1. Output: Finally, the script provides an output stating that Service Health Alerts have been created for the subscription.

In summary, this script creates Azure service health alerts for each VM in a recovery plan context, and it assigns the alert notifications to contributors and owners of each VM's resource group. These alerts notify the appropriate people about "ServiceHealth" events related to their resource groups, which might indicate issues or incidents affecting the resources in those groups.

> **_NOTE:_**  As this is for DR Scenarios we need to also ensure the manual steps are included below. If your script does not complete successfully and you need to manually achieve DRServiceHealthAlerts please follow the below link.

## [Configure Resource Health alerts in the Azure portal](https://learn.microsoft.com/en-us/azure/service-health/resource-health-alert-monitor-guide)

---------------------------------------------------------------------------------------------

