Get-azvm | get-azvmextension -name MicrosoftMonitoringAgent| select VMName, Name, PublicSettings

<#
$vmsNotBackedUp += Get-AzVM |
    Where-Object{$_.Id -in $resourceIDs} |
    Add-Member -MemberType NoteProperty -Name 'Subscription' -Value $sub.id -PassThru
#>
  