# Description
This Policy is for use with the Azure Update Management Center and will be used to deploy using Tags. For the below to apply you need to add a tag on your Virtual machine with a key "Patch" and a value "Yes".

1. [Azure Policy Definition](./UpdateManagementCenterPolicy/UpdateManagementCenterPolicy.json)
1. [Desired State Config for Windows Update from PowerShell Gallery](https://www.powershellgallery.com/packages/xWindowsUpdate/3.0.0-preview0001)
1. [DSC Community with examples](https://github.com/dsccommunity/xWindowsUpdate/blob/master/source/Examples/Resources/xWindowsUpdateAgent/1-xWindowsUpdateAgent_SetWuaScheduledFromWu_Config.ps1)
1. [Really cool article to do this yourself](https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/azure-policy-guest-configuration-using-tags-for-configuration-of/bc-p/2912644#M4044)

## Notes
- **In Future releases of these scripts I will add a Guest Assignments and DSC MOF file to set the correct Windows Update Settings
- *Felt Cute, might use [WindowsUpdate.ps1](./WindowsUpdateDSC/WindowsUpdate.ps1)
