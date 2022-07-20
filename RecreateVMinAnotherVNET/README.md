Process Description:
•	We will use main.tf to create the server (If not created already) by running the azure-pipelines.yml Pipeline
•	We will run a second Pipeline called azure-pipelinesAfter.yml that calls the PowerShell.ps1 file that will delete the computer object,  and call the mainAfter.tf file which will change the NIC Subnet and add the server back to the original OS Disk.
•	The second pipeline and mainAfter.tf file is in a separate folder otherwise terraform will just combine the two “.tf” files and try and build both scenarios

Requirements:
Use an Azure DevOps Environment with a Service Principal set up
Have some hosted agents ready to execute pipelines
Updates the Variables:
Variables to Update in the Main.tf
Lines 9 – 12
All The Terraform Resources Names
Lines 110 -112

Variables to Update in the azure-pipelines.yml
•	Lines 19 – 23
•	Lines 39 – 43
•	Line 48
•	Line 53

Variables to update in the Powershell.ps1
•	Line 21 – 23

Variables to Update in the mainAfter.tf
•	Lines 9 – 12
•	All The Terraform Resources Names

Variables to Update in the azure-pipelinesAfter.yml
•	Line 18
•	Lines 37 – 41
•	Lines 59 – 63 
•	Line 69
•	Line 75

Example
1.	The Directory Structure

![image](https://user-images.githubusercontent.com/23274490/160882603-94b80529-f3ff-4775-a483-dee30078dc91.png)

2.	The two pipelines

![image](https://user-images.githubusercontent.com/23274490/160882648-5e7ae485-8113-43d5-887e-c8459d978864.png)

3.	Running the azure-pipelines.yml

![image](https://user-images.githubusercontent.com/23274490/160882725-967781ce-3ed9-42d0-aac0-edc74e1aa15a.png)

![image](https://user-images.githubusercontent.com/23274490/160882741-4d78568e-9b0e-42da-b573-f135bb192326.png)

4.	See the resources in Azure

![image](https://user-images.githubusercontent.com/23274490/160882775-67f60916-60e2-4905-ba53-4de8568685a5.png)

5.	Execute the Second Pipeline

![image](https://user-images.githubusercontent.com/23274490/160882817-3d4f3072-d9e1-4b14-bf25-1d6e54e355bb.png)
![image](https://user-images.githubusercontent.com/23274490/160882891-75f2af1c-329b-4d40-9b1d-4b9ea5eb3365.png)

5.1 As expected PowerShell deletes the VM

![image](https://user-images.githubusercontent.com/23274490/160882934-0f4830d1-8b77-4f41-bd32-35b96e4a4d51.png)

![image](https://user-images.githubusercontent.com/23274490/160882990-1949ed27-0ded-4dfe-a3b8-b6a3bb8f4344.png)

![image](https://user-images.githubusercontent.com/23274490/160883036-ec5e420c-96b3-4222-8e48-9f6c80315739.png)

6.	See the resources in Azure (Server has been recreated and NIC has been placed in correct Virtual Network)

![image](https://user-images.githubusercontent.com/23274490/160883065-473f0dc5-f07f-47c7-9fea-aad8b8f2dc99.png)
