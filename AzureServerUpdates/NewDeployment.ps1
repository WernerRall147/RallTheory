[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)][string]$ComputerFQDN
    , [Parameter(Mandatory = $true)][int]$RunID
    , [Parameter(Mandatory = $False)][String]$SoftwareUpdateConfigurationName
)

# Connect to Azure with RunAs account
Write-verbose "Connecting to Azure with Runas..." -Verbose
$servicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
$addAccountParams = @{
    'ServicePrincipal'      = $true
    'TenantId'              = $servicePrincipalConnection.TenantId
    'ApplicationId'         = $servicePrincipalConnection.ApplicationId
    'CertificateThumbprint' = $servicePrincipalConnection.CertificateThumbprint
}
$null = Add-AzAccount @addAccountParams
$null = Select-AZSubscription -SubscriptionId $servicePrincipalConnection.SubscriptionID
#Only Used when Patching Azure Servers, modify Line 42
$ComputerResID = Get-AzResource -Name $ComputerFQDN | select ResourceId
#Build the SoftwareUpdateConfigurationName

IF ($SoftwareUpdateConfigurationName) {
    $UpdateDeploymentName = $SoftwareUpdateConfigurationName
}
Else {
    $UpdateDeploymentName = "Patching_" + $ComputerFQDN + "_" + $RunID
}

$AutomationResourceGroup = "<Resource Group>"
$AutomationAccount = "<Automation Account>"

#Build the Schedule Object
$StartTime = (Get-Date).AddMinutes(7)

$TimeZone = ([System.TimeZoneInfo]::Local).Id
$Schedule = New-AzAutomationSchedule -AutomationAccountName $AutomationAccount -Name $UpdateDeploymentName -StartTime $StartTime -OneTime -ResourceGroupName $AutomationResourceGroup -TimeZone $TimeZone

#Build the SUC deployment:
$duration = New-TimeSpan -Minutes 360

$null = New-AzAutomationSoftwareUpdateConfiguration -ResourceGroupName $AutomationResourceGroup -AutomationAccountName $AutomationAccount -Schedule $schedule -Windows -AzureVMResourceId $ComputerResID -IncludedUpdateClassification UpdateRollup, Critical, Security, Updates -Duration $duration

$EndTime = $(Get-Date).AddMinutes(20)
$i = 1

#Get the Deployment Run to return a RunID
While (-NOT($NewSuc)) {
    $NewSuc = Get-AzAutomationSoftwareUpdateRun -ResourceGroupName $AutomationResourceGroup -AutomationAccountName $AutomationAccount -SoftwareUpdateConfigurationName $UpdateDeploymentName | Select-Object -ExcludeProperty Description
    IF ($NewSUC) {
        #AUM is created.
<#
        $NewSUC.PSObject.Properties | ForEach-Object {
            Write-output "-------"
            Write-Output $_.Name
            Write-Output $_.Value
        }
#>
        Write-Output ($NewSuc | ConvertTo-Json)
    }
    ELSE {
        Start-sleep 10
        Write-Verbose "Waiting on AUM to create deployment:  $i" -Verbose
        ++$i
        $Date = Get-Date
        IF ($EndTime -lt $Date) {
            #Loop has been running too long.  Exit.
            $NewSuc = $true
        }
    }
}