param($eventGridEvent, $TriggerMetadata)

# Make sure to pass hashtables to Out-String so they're logged correctly
$eventGridEvent | Out-String | Write-Host
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