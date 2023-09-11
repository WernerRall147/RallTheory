#Normally Fabric has a format of something like this 'asr-a2a-default-eastus'

$VaultName = '#TODO'
$vault = Get-AzRecoveryServicesVault -Name $VaultName
Set-AzRecoveryServicesAsrVaultContext -Vault $vault
$fabric = Get-AzRecoveryServicesAsrFabric -Name "#TODO"
$container = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric
$pi = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $container

# Create a new DataTable object
$table2 = New-Object System.Data.DataTable
# Add columns to the table
$table2.Columns.Add("SourceVMName", [string])
$table2.Columns.Add("FailoverVMName", [string])
$table2.Columns.Add("StaticNICIP", [string])

# Output the primary IP failover information
Foreach($p in $pi){

# Add rows to the table
$SourceVMName = ($p.RecoveryAzureVMName).ToString()
$FailoverVMName = ($p.TfoAzureVMName).ToString()
$StaticNICIP = ($p.NicDetailsList.IpConfigs.StaticIPAddress).ToString()
$table2.Rows.Add("$SourceVMName", "$FailoverVMName", "$StaticNICIP")

Write-Output $table2
}