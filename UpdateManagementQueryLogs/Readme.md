**Original Fork (credit)**
<https://github.com/scautomation/Azure-Automation-Update-Management-Workbooks>

# Azure Monitor Update Management Patch Compliance Workbooks

## Description

Update Management Patch Compliance Workbook that also now includes some Azure Resource Graph Queries and a few different Tabs. These can be used for reporting purposes.

## Requirements
1. Azure Update Management should be enabled
1. Azure Log Analytics linked to the Update Management
1. Permissions to the Azure Portal and resources above

## Install

1. Go to Azure Monitor, Workbooks, New

![image](https://user-images.githubusercontent.com/23274490/170032890-980a1ac5-6cca-457b-a85c-147e82051766.png)

2. Click the Advanced Editor Button

![image](https://user-images.githubusercontent.com/23274490/170033119-de718069-6879-4d8a-a158-18b7c9183392.png)

3. In a new tab go to [<UpdateManagementWorkbook.json>](https://raw.githubusercontent.com/WernerRall147/Powershell/main/UpdateManagementQueryLogs/UpdateManagementWorkbook.json) an copy everything

<img width="550" alt="image" src="https://user-images.githubusercontent.com/23274490/170033476-d77ebeef-6cba-4a13-8230-4e19ab5cf3fb.png">

4. Switch back to the Azure Portal and paste everything in the Gallery Template (Remove anything that was in the block or paste over it)

<img width="852" alt="image" src="https://user-images.githubusercontent.com/23274490/170033791-889289f0-aee6-43df-a0ee-2c74130585f2.png">

5. Click Apply and then Done Editing

![image](https://user-images.githubusercontent.com/23274490/170033907-df1de752-5327-4b67-80d9-90ee54978746.png)

## Using the Report

Select the Workspace or Workspaces you would like to report on and you should see a report similair to below

![image](https://user-images.githubusercontent.com/23274490/170034465-c44d6cfb-2bc4-417c-bf58-efb50bacc54a.png)

![image](https://user-images.githubusercontent.com/23274490/170034492-650f03b2-bff5-43f5-94a6-73bf8867d7f1.png)

When you click on any of the machines "Updates Needed by <unset>" can be seen at the bottom of the report page

![image](https://user-images.githubusercontent.com/23274490/170034652-c9dba54d-fd5b-4f54-986e-b8c0f0198ca7.png)

There are also other pages in the reports called Computers and Alerts


 ## Diving into Alerts
 
 On the alerts page you can drill in to the Alerts section of Automation Management Account
 
 ![image](https://user-images.githubusercontent.com/23274490/170035806-6440ce67-c962-4d7b-b650-92830ab00a1b.png)

 and you can apply further splitting to get a view of the status of recent update cycles
  
 ![image](https://user-images.githubusercontent.com/23274490/170036289-e46072a4-2392-4fa9-84f8-3b8685d15f73.png)

 
