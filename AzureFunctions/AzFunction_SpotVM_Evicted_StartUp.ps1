using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

try {
    # Authenticate using managed identity or other secure methods (avoid interactive login)
    Connect-AzAccount -Identity 

    # Retrieve the list of subscriptions
    $subscriptions = Get-AzSubscription

    foreach ($subscription in $subscriptions) {
        Set-AzContext -Subscription $subscription.Id

        # Query spot VMs (modify this part as needed)
        $spotVms = Get-AzVM -Status | select-object Priority, Name, ResourceGroupName, PowerState | Where-Object { $_.Priority -eq 'Spot' }

        # Process the spot VMs (e.g., log, return data, etc.)
        foreach ($vm in $spotVms) {
            Write-Host "Spot VM: $($vm.Name) in resource group: $($vm.ResourceGroupName) is $($vm.PowerState)"
            $vm | Where-Object { $_.PowerState -eq 'VM deallocated' } | ForEach-Object {Start-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -ErrorAction Stop}
    
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

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
