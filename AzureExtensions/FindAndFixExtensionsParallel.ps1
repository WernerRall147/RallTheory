# Connect to Azure account
Write-Output "Connecting to Azure account using managed identity..."
try {
    Connect-AzAccount -Identity
    Write-Output "Connected to Azure account."
} catch {
    Write-Output "Failed to connect to Azure account: $_"
    exit 1
}

# Define the Azure Resource Graph query
$query = @"
resources
| where type in ('microsoft.hybridcompute/machines/extensions', 'microsoft.compute/virtualmachines/extensions')
    and properties.provisioningState != 'Succeeded'
| extend VMId = toupper(substring(id, 0, indexof(id, '/extensions'))),
        ExtensionName = tostring(name),
        ExtensionType = tostring(properties.type),
        ExtensionPublisher = tostring(properties.publisher),
        Provisioned = tostring(properties.provisioningState)
| join kind=leftouter (
    resources
    | where type in ('microsoft.hybridcompute/machines', 'microsoft.compute/virtualmachines')
    | extend VMId = toupper(id),
            OSName = tostring(name),
            SubId = tostring(subscriptionId),
            RSG = tostring(resourceGroup),
            LOC = tostring(location),
            OSType = tostring(properties.storageProfile.osDisk.osType)
) on VMId
| summarize Extensions = make_list(ExtensionName), ExtensionStates = make_list(Provisioned) by OSName, SubId, RSG, LOC, OSType, ExtensionName, ExtensionPublisher, ExtensionType
| where array_length(Extensions) > 0
"@

# Run the query and get results
Write-Output "Running the Azure Resource Graph query..."
try {
    $results = Search-AzGraph -Query $query -First 1000
    Write-Output "Query executed. Processing results..."
    Write-Output "Raw results:"
    $results | Format-Table -AutoSize
} catch {
    Write-Output "Failed to execute query: $_"
    exit 1
}

# Process the results directly
try {
    $affectedVMs = $results
    Write-Output "Processed query results successfully."
} catch {
    Write-Output "Failed to process query results: $_"
    exit 1
}

# Function to fix broken extensions on a single VM
function Fix-BrokenExtensions {
    param (
        [string]$ResourceGroupName,
        [string]$VMName,
        [string]$ExtensionName,
        [string]$Publisher,
        [string]$ExtensionType
    )

    Write-Output "Removing broken extension '$ExtensionName' from VM '$VMName' in resource group '$ResourceGroupName'..."
    try {
        # Remove the broken extension
        Remove-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -Name $ExtensionName -Force
        Write-Output "Removed extension '$ExtensionName' from VM '$VMName'."
    } catch {
        Write-Output "Failed to remove extension '$ExtensionName' from VM '$VMName': $_"
    }

    Write-Output "Reinstalling extension '$ExtensionName' to VM '$VMName' with publisher '$Publisher' and type '$ExtensionType'..."
    try {
        # Reinstall the extension (adjust settings as necessary for your environment)
        $extensionParams = @{
            ResourceGroupName = $ResourceGroupName
            VMName            = $VMName
            Name              = $ExtensionName
            Publisher         = $Publisher
            ExtensionType     = $ExtensionType
            TypeHandlerVersion = '1.0' # Replace with the correct version if needed
        }
        Set-AzVMExtension @extensionParams
        Write-Output "Reinstalled extension '$ExtensionName' to VM '$VMName'."
    } catch {
        Write-Output "Failed to reinstall extension '$ExtensionName' to VM '$VMName': $_"
    }
}

# Run the fixes in parallel
Write-Output "Starting to fix broken extensions on affected VMs in parallel..."
foreach ($vm in $affectedVMs) {
    Write-Output "Processing VM properties:"
    Write-Output "VMName: $($vm.OSName)"
    Write-Output "ResourceGroupName: $($vm.RSG)"
    Write-Output "Extensions: $($vm.Extensions)"
    Write-Output "ExtensionStates: $($vm.ExtensionStates)"
    Write-Output "ExtensionPublisher: $($vm.ExtensionPublisher)"
    Write-Output "ExtensionType: $($vm.ExtensionType)"

    $ResourceGroupName = $vm.RSG
    $VMName = $vm.OSName
    $Extensions = $vm.Extensions
    $Publisher = $vm.ExtensionPublisher
    $ExtensionType = $vm.ExtensionType

    Write-Output "Processing VM '$VMName' in resource group '$ResourceGroupName'..."
    foreach ($extension in $Extensions) {
        Write-Output "Fixing extension '$extension' on VM '$VMName' with publisher '$Publisher' and type '$ExtensionType'..."
        Fix-BrokenExtensions -ResourceGroupName $ResourceGroupName -VMName $VMName -ExtensionName $extension -Publisher $Publisher -ExtensionType $ExtensionType
        Write-Output "Fixed extension '$extension' on VM '$VMName'."
    }
}
Write-Output "Completed fixing broken extensions on all affected VMs."
