#connect to Azure
Connect-AzAccount -UseDeviceAuthentication

#Normally Fabric has a format of something like this 'asr-a2a-default-eastus'
$VaultName = Read-Host -Prompt "Enter the name of the Recovery Services Vault"
$vault = Get-AzRecoveryServicesVault -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $vault
$fabricName = Read-Host -Prompt "Enter the name of the Fabric, Fabric has a format of something like this 'asr-a2a-default-eastus'"
$fabric = Get-AzRecoveryServicesAsrFabric -Name $fabricName
$container = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric
$pi = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $container

# Create a new DataTable object
$table2 = New-Object System.Data.DataTable
# Add columns to the table
$table2.Columns.Add("SourceVMName", [string])
$table2.Columns.Add("FailoverVMName", [string])
$table2.Columns.Add("StaticNICIP", [string])
$table2.Columns.Add("FailoverNICIP", [string])

# Output the primary IP failover information
Foreach($p in $pi){

# Add rows to the table
$SourceVMName = ($p.RecoveryAzureVMName).ToString()
$FailoverVMName = ($p.TfoAzureVMName).ToString()
$StaticNICIP = ($p.NicDetailsList.IpConfigs.StaticIPAddress).ToString()
$FailoverNICIP = ($p.NicDetailsList.IpConfigs.RecoveryIPAddressType).ToString()
$table2.Rows.Add("$SourceVMName", "$FailoverVMName", "$StaticNICIP", "$FailoverNICIP")
}

Write-Output $table2 | Format-Table -AutoSize
