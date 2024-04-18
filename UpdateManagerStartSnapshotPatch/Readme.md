# Introduction
Now that Azure Update Manager is the most supported way to patch your Azure VMs I decided to create some Pre and Post Tasks. The First pre task will be to Start up certain VM's that have tags. The next pre task will be to do a snapshot of the OS Disk in case the patch does anything unwanted we can very easily create a disk from the Snapshot. *There will be more pre and post tasks added as required.

## Requirements
- Understand Azure Automation Account
- an Azure Automation Account
- Basic understanding of Runbooks and PowerShell
- Understand and use Azure Update Manager

## Steps
- Create your Maintenance Configuration Schedules for Azure Update Manager
- We need to import our Runbooks into Azure Automation Account
- Create webhooks for our runbooks
- We need to set up and Event Grid System Topic
- We need to set up a subscription to the topic and call the webhook as an endpoint