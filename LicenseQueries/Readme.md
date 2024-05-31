# LicenseQueries Folder Documentation

This folder contains scripts and resources related to querying and managing product licenses. 

# AutomationAccountComponent 

This folder contains the runbooks that will create a custom Log Analytics Table to keep track of licensing. It would be good to run this query once a day. We will then plug in Power BI on top of this later. 

# LicenseNames

The scripts in this folder are designed to work with the product names and service plan identifiers provided by Microsoft. Unfortunately, direct querying of the Microsoft reference page is not possible. You can find the reference page at the following URL:
https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference

To overcome this limitation, we have created a CSV file that matches the data from the reference page. This CSV file can be used in conjunction with our PowerShell scripts to manage licenses effectively.

Please refer to the individual script files for more detailed usage instructions.

# Logic App Components

The Logic app we use allows us to email us the CSV file with groups that were changed. 