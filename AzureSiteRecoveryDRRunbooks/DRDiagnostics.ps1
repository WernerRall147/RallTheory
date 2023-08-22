<#
    .DESCRIPTION
        A few tasks you might want to run during an Azure Site Recovery DR Scenario. These tasks have been split out into seperate scripts

    .NOTES
        AUTHOR: Werner Rall
        LASTEDIT: 20230822
        https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-runbook-automation
#>
param (
[parameter(Mandatory=$false)]
[Object]$RecoveryPlanContext,
[parameter(Mandatory=$false)]
[Object]$diagnosticsStorageAccountName
)

Write-Output "Please enable appropriate RBAC permissions to the system identity of this automation account. Otherwise, the runbook may fail..."
#Log in with the Managed Identity
try
{
    Write-Output "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

Write-Output "Getting variables from Automation Account Store"
$diagnosticsStorageAccountName = Get-AutomationVariable -Name 'diagnosticsStorageAccountName'


#Decyfer RecoveryPlan Context
$VMinfo = $RecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | Select-Object -ExpandProperty Name
$vmMap = $RecoveryPlanContext.VmMap

    foreach($VMID in $VMinfo)
    {
        $VM = $vmMap.$VMID
            if( !(($Null -eq $VM) -Or ($Null -eq $VM.ResourceGroupName) -Or ($Null -eq $VM.RoleName))) {
            #this check is to ensure that we skip when some data is not available else it will fail
            Write-output "Resource group name ", $VM.ResourceGroupName
            }
        }


    #Create the default Diagnostics Config file, can also be found at https://raw.githubusercontent.com/WernerRall147/RallTheory/main/AzureSiteRecoveryDRRunbooks/DiagnosticsConfiguration.json
$diagnosticsconfigfile = @"
{
  "PublicConfig": {
      "StorageAccount": "(TODOUpdateStorac)",
      "WadCfg": {
        "DiagnosticMonitorConfiguration": {
          "overallQuotaInMB": 5120,
          "Metrics": {
            "resourceId": "(TODOUpdateResID)" ,
            "MetricAggregation": [
              {
                "scheduledTransferPeriod": "PT1H"
              },
              {
                "scheduledTransferPeriod": "PT1M"
              }
            ]
          },
          "DiagnosticInfrastructureLogs": {
            "scheduledTransferLogLevelFilter": "Error"
          },
          "PerformanceCounters": {
            "scheduledTransferPeriod": "PT1M",
            "PerformanceCounterConfiguration": [
              {
                "counterSpecifier": "\\Processor Information(_Total)\\% Processor Time",
                "unit": "Percent",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Processor Information(_Total)\\% Privileged Time",
                "unit": "Percent",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Processor Information(_Total)\\% User Time",
                "unit": "Percent",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Processor Information(_Total)\\Processor Frequency",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\System\\Processes",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Process(_Total)\\Thread Count",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Process(_Total)\\Handle Count",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\System\\System Up Time",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\System\\Context Switches/sec",
                "unit": "CountPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\System\\Processor Queue Length",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Memory\\% Committed Bytes In Use",
                "unit": "Percent",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Memory\\Available Bytes",
                "unit": "Bytes",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Memory\\Committed Bytes",
                "unit": "Bytes",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Memory\\Cache Bytes",
                "unit": "Bytes",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Memory\\Pool Paged Bytes",
                "unit": "Bytes",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Memory\\Pool Nonpaged Bytes",
                "unit": "Bytes",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Memory\\Pages/sec",
                "unit": "CountPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Memory\\Page Faults/sec",
                "unit": "CountPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Process(_Total)\\Working Set",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Process(_Total)\\Working Set - Private",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\% Disk Time",
                "unit": "Percent",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\% Disk Read Time",
                "unit": "Percent",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\% Disk Write Time",
                "unit": "Percent",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\% Idle Time",
                "unit": "Percent",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Bytes/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Transfers/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Reads/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Writes/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk Queue Length",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\% Free Space",
                "unit": "Percent",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\LogicalDisk(_Total)\\Free Megabytes",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Network Interface(*)\\Bytes Total/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Network Interface(*)\\Bytes Sent/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Network Interface(*)\\Bytes Received/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Network Interface(*)\\Packets/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Network Interface(*)\\Packets Sent/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Network Interface(*)\\Packets Received/sec",
                "unit": "BytesPerSecond",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Network Interface(*)\\Packets Outbound Errors",
                "unit": "Count",
                "sampleRate": "PT60S"
              },
              {
                "counterSpecifier": "\\Network Interface(*)\\Packets Received Errors",
                "unit": "Count",
                "sampleRate": "PT60S"
              }
            ]
          },
          "WindowsEventLog": {
            "scheduledTransferPeriod": "PT1M",
            "DataSource": [
              {
                "name": "Application!*[System[(Level = 1 or Level = 2 or Level = 3)]]"
              },
              {
                "name": "Security!*[System[band(Keywords,4503599627370496)]]"
              },
              {
                "name": "System!*[System[(Level = 1 or Level = 2 or Level = 3)]]"
              }
            ]
          }
        }
      }
    },
    "PrivateConfig": {
      "storageAccountName": "(TODOUpdateStorac)",
      "storageAccountKey": "(TODOUpdateStKey)",
      "storageAccountEndPoint": "https://(TODOUpdateStorac).blob.core.windows.net"
  }
}  
"@

  #Get all ARM resources from DR
   # $DestinationResourceGroup = Get-AZResourcegroup -Name $VM.ResourceGroupName
    $DestinationResources = Get-AzVM -ResourceGroupName $VM.ResourceGroupName
    $DestinationStorageAccountName = (Get-AzStorageAccount -ResourceGroupName $VM.ResourceGroupName -Name $diagnosticsStorageAccountName).StorageAccountName
    $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $VM.ResourceGroupName -Name $DestinationStorageAccountName).Value[0]

# Ensure Diagnostics Settings are enabled
    try {
    foreach ($drres in $DestinationResources) {
      Write-Output "Checking Diagnostics Settings" ($DiagSettings = Get-AzVMDiagnosticsExtension -ResourceGroupName $VM.ResourceGroupName -VMName ($drres).Name)
        if ($null -eq $DiagSettings) {
            $diagnosticsconfig_path = "$env:SystemDrive\temp\DiagnosticsConfiguration.json"
            $diagnosticsconfigfile | Out-File -FilePath $diagnosticsconfig_path

            Write-Output "Updating Diagnostic Settings file with variables"
            $diagnosticsconfig_update1 = (Get-Content $diagnosticsconfig_path).Replace("(TODOUpdateResID)",$drres.Id) | Set-Content $diagnosticsconfig_path
            $diagnosticsconfig_update1 
            $diagnosticsconfig_update2 = (Get-Content $diagnosticsconfig_path).Replace("(TODOUpdateStorac)",$DestinationStorageAccountName) | Set-Content $diagnosticsconfig_path
            $diagnosticsconfig_update2
            $diagnosticsconfig_update3 = (Get-Content $diagnosticsconfig_path).Replace("(TODOUpdateStKey)",$StorageAccountKey) | Set-Content $diagnosticsconfig_path
            $diagnosticsconfig_update3

           
            Write-Output "Enabling Diagnostic Settings" (Set-AzVMDiagnosticsExtension -ResourceGroupName $VM.ResourceGroupName -VMName ($drres).Name -DiagnosticsConfigurationPath $diagnosticsconfig_path -storageAccountName $DestinationStorageAccountName -StorageAccountKey $StorageAccountKey)
            }else {
                Write-Output "Diagnostic Settings Correct"
            }
    }
}
catch {
    Write-Output "An error occurred: $($_.Exception.Message)"
}

Write-Output "The script has completed with or without errors."