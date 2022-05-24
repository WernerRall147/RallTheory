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


