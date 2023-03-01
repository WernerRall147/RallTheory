# A few tasks you might want to run during an Azure Site Recovery DR Scenario

# Pre Requisites
To complete a DR with Azure Site Recovery we need like-for-like resources in Primary and Failover Regions
For the below scripts to work with a Recovery Plan we need the below resources in our Failover region
- Log Analytics Workspace
- Azure Automation Account with Managed Identity that has contributor access in Primary and Failover Region
- Storage Account for Diagnostic settings
- Destination NSG attached to the Failover region Virtual Network Subnet

# Using the runbooks
Import all the below runbooks into your Failover Region Automation Account and updates all the variables labeled #TODO

# This runbook is so that your source NSG Rules sync with the Destination NSG Rules
1. Check inbound port rules if NSGs are on Vnets - Run this runbook seperately

# These Runbooks can be added to the Recovery Plan
1.   Ensure Diagnostics Settings are enabled - Run in recovery Plan
2.  Ensure Backup gets enabled - Run in Recovery Plan
3.  Ensure Insights get enabled - Run in Recovery Plan
4.  Create Alerts for DR Resource Group - Run in Recovery Plan

Please replace all the #TODO  in the scripts with your required variables
