# Function to fix broken extensions on a single VM
function Fix-BrokenExtensions {
    param (
        [string]$ResourceGroupName,
        [string]$VMName,
        [string]$ExtensionName
    )

    # Remove the broken extension
    Remove-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name $ExtensionName -Force

    # Reinstall the extension (adjust settings as necessary for your environment)
    $extensionParams = @{
        ResourceGroupName = $ResourceGroupName
        VMName            = $VMName
        Name              = $ExtensionName
        Publisher         = 'Microsoft.Compute'
        ExtensionType     = $ExtensionName
        TypeHandlerVersion = '1.0' # Replace with the correct version if needed
    }
    Set-AzVMExtension @extensionParams
}

# Fix broken extensions for all affected VMs
foreach ($vm in $affectedVMs) {
    $ResourceGroupName = $vm.RSG
    $VMName = $vm.OSName
    $Extensions = $vm.Extensions

    foreach ($extension in $Extensions) {
        Fix-BrokenExtensions -ResourceGroupName $ResourceGroupName -VMName $VMName -ExtensionName $extension
    }
}
