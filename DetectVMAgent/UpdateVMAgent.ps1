$vm  = get-AzVM -ResourceGroupName <rg> -name <vm>
$vm.OSProfile.AllowExtensionOperations = $true
$vm | Update-Azvm


