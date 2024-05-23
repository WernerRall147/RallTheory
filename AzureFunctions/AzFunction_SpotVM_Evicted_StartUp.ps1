using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Import required modules
try {
    Write-Output "Importing required modules..."
    Import-Module Az.Accounts -ErrorAction Stop
    Write-Output "Az.Accounts module imported successfully."
    Import-Module Az.Compute -ErrorAction Stop
    Write-Output "Az.Compute module imported successfully."
} catch {
    Write-Error "Failed to import required modules. Please ensure Az.Accounts and Az.Compute are installed."
    exit
}

# Write to the Azure Functions log stream.
Write-Output "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}
Write-Output "Name value: $name"


try {
    # Authenticate using managed identity or other secure methods (avoid interactive login)
    Write-Output "Trying to Connect using the Managed Identity"
    Connect-AzAccount -Identity 
    Write-Output "Connected to Azure successfully."


    # Retrieve the list of subscriptions
    $subscriptions = Get-AzSubscription
    Write-Output "Retrieved subscriptions: $($subscriptions.Count)"


    foreach ($subscription in $subscriptions) {
        Set-AzContext -Subscription $subscription.Id
        Write-Output "Set context to subscription: $($subscription.Id)"

        # Query spot VMs (modify this part as needed)
        $spotVms = Get-AzVM -Status | select-object Priority, Name, ResourceGroupName, PowerState | Where-Object { $_.Priority -eq 'Spot' }
        Write-Output "Retrieved spot VMs: $($spotVms.Count)"

        # Process the spot VMs (e.g., log, return data, etc.)
        foreach ($vm in $spotVms) {
            Write-Host "Spot VM: $($vm.Name) in resource group: $($vm.ResourceGroupName) is $($vm.PowerState)"
            Write-Output "Spot VM: $($vm.Name) in resource group: $($vm.ResourceGroupName) is $($vm.PowerState)"
            try {
                $vm | Where-Object { $_.PowerState -eq 'VM deallocated' } | ForEach-Object {Start-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -ErrorAction Stop}
                Write-Output "Started the Spot VM: $($vm.Name) in resource group: $($vm.ResourceGroupName)"
            } catch {
                Write-Error -Message $_.Exception
            }
        }
    }
}
catch {
    # Handle exceptions (log, return error response, etc.)
    Write-Error -Message $_.Exception
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

Write-Output "End of Script"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
