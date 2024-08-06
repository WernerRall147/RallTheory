<#
    .SYNOPSIS
        This script manages the power state of Azure virtual machines based on a specified tag and its value which defines the schedule.
 
    .DESCRIPTION
        This script checks all Azure virtual machines for a tag named "AutoShutdownSchedule" with a value defining the schedule,
        e.g. "10PM -> 6AM". It then compares the current time with the schedule and starts or stops the VMs accordingly.
 
    .PARAMETER TagName
        The name of the tag to look for on virtual machines.
 
    .PARAMETER ManagementGroupId
        The ID of the Azure management group to operate on.
 
    .PARAMETER Simulate
        If $true, the script will only simulate the actions without making any changes.
 
    .EXAMPLE
        .\StartStopVMsBasedOnTag.ps1 -TagName "AutoShutdownSchedule" -ManagementGroupId "MngEnv" -Simulate $true
 
#>
param (
    [parameter(Mandatory = $true)]
    [string]$TagName,
 
    [parameter(Mandatory = $true)]
    [string]$ManagementGroupId,
 
    [parameter(Mandatory = $false)]
    [bool]$Simulate = $false
)
 
$VERSION = "1.0.0"

## Authentication
Write-Output ""
Write-Output "------------------------ Authentication ------------------------"
Write-Output "Logging into Azure ..."

try
{
    # Ensures you do not inherit an AzContext in your runbook
    $null = Disable-AzContextAutosave -Scope Process

	$null= Connect-AzAccount -Identity
    Write-Output "Successfully logged into Azure." 
    $AzureContext = Set-AzContext -SubscriptionId $SubscriptionId    

} 
catch
{
    
        Write-Error -Message $_.Exception
        throw $_.Exception
    
}


## End of authentication

## Getting all virtual machines
Write-Output ""
Write-Output ""
Write-Output "---------------------------- Status ----------------------------"
Write-Output "Getting all virtual machines from all resource groups ..."

# Function to retrieve all subscriptions under a management group
function Get-SubscriptionsUnderManagementGroup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ManagementGroupId
    )

    # Array to store subscription IDs
    $subscriptionIds = @()

    # Get the management group hierarchy
    $managementGroup = Get-AzManagementGroup -GroupId $ManagementGroupId -Expand

    if ($managementGroup -and $managementGroup.Children) {       
        # Loop through each child in the management group
        foreach ($child in $managementGroup.Children) {
            if ($child.Type -eq "Microsoft.Management/managementGroups") {
                # Recursively get subscriptions from child management groups
                $childManagementGroupId = $child.Name
                $subscriptionIds += Get-SubscriptionsUnderManagementGroup -ManagementGroupId $childManagementGroupId
            } elseif ($child.Type -match "/subscriptions") {
                # Extract subscription ID
                $subscriptionId = [regex]::Match($child.Name, "([a-f0-9-]{36})").Value
                if ($subscriptionId) {
                    $subscriptionIds += $subscriptionId
                }
            }
        }
    }

    return $subscriptionIds
}

# Get all subscription IDs under the management group
$subscriptionIds = Get-SubscriptionsUnderManagementGroup -ManagementGroupId $ManagementGroupId

function CheckScheduleEntry ([string]$TimeRange) {  
    $rangeStart, $rangeEnd, $parsedDay = $null
    $currentTime = (Get-Date).ToUniversalTime().AddHours(2)
    $midnight = $currentTime.AddDays(1).Date
 
    try {
        if ($TimeRange -like "*->*") {
            $timeRangeComponents = $TimeRange -split "->" | ForEach-Object { $_.Trim() }
            if ($timeRangeComponents.Count -eq 2) {
                $rangeStart = Get-Date $timeRangeComponents[0]
                $rangeEnd = Get-Date $timeRangeComponents[1]
 
                if ($rangeStart -gt $rangeEnd) {
                    if ($currentTime -ge $rangeStart -and $currentTime -lt $midnight) {
                        $rangeEnd = $rangeEnd.AddDays(1)
                    }
                    else {
                        $rangeStart = $rangeStart.AddDays(-1)
                    }
                }
            }
            else {
                Write-Output "`WARNING: Invalid time range format. Expects valid .Net DateTime-formatted start time and end time separated by '->'" 
            }
        }
        else {
            if ([System.DayOfWeek].GetEnumValues() -contains $TimeRange) {
                if ($TimeRange -eq (Get-Date).DayOfWeek) {
                    $parsedDay = Get-Date "00:00"
                }
            }
            else {
                $parsedDay = Get-Date $TimeRange
            }
 
            if ($parsedDay -ne $null) {
                $rangeStart = $parsedDay
                $rangeEnd = $parsedDay.AddHours(23).AddMinutes(59).AddSeconds(59)
            }
        }
    }
    catch {
        Write-Output "`WARNING: Exception encountered while parsing time range. Details: $($_.Exception.Message). Check the syntax of entry, e.g. '<StartTime> -> <EndTime>', or days/dates like 'Sunday' and 'December 25'"   
        return $false
    }
 
    if ($currentTime -ge $rangeStart -and $currentTime -le $rangeEnd) {
        return $true
    }
    else {
        return $false
    }
}
 
function AssertVirtualMachinePowerState {
    param (
        [Object]$VirtualMachine,
        [string]$DesiredState,
        [bool]$Simulate
    )
 
    $resourceManagerVM = Get-AzVM -ResourceGroupName $VirtualMachine.ResourceGroupName -Name $VirtualMachine.Name -Status
    $currentStatus = $resourceManagerVM.Statuses | Where-Object { $_.Code -like "PowerState*" }
    $currentStatus = $currentStatus.Code -replace "PowerState/", ""
 
    if ($DesiredState -eq "Started" -and $currentStatus -notmatch "running") {
        if ($Simulate) {
            Write-Output "[$($VirtualMachine.Name)]: SIMULATION -- Would have started VM. (No action taken)"
        }
        else {
            Write-Output "[$($VirtualMachine.Name)]: Starting VM"
            $resourceManagerVM | Start-AzVM
        }
    }
    elseif ($DesiredState -eq "StoppedDeallocated" -and $currentStatus -ne "deallocated") {
        if ($Simulate) {
            Write-Output "[$($VirtualMachine.Name)]: SIMULATION -- Would have stopped VM. (No action taken)"
        }
        else {
            Write-Output "[$($VirtualMachine.Name)]: Stopping VM"
            $resourceManagerVM | Stop-AzVM -Force
        }
    }
    else {
        Write-Output "[$($VirtualMachine.Name)]: Current power state [$currentStatus] is correct."
    }
}
 
try {
    $currentTime = (Get-Date).ToUniversalTime()
    Write-Output "Script started. Version: $VERSION"
    if ($Simulate) {
        Write-Output "*** Running in SIMULATE mode. No power actions will be taken. ***"
    }
    else {
        Write-Output "*** Running in LIVE mode. Schedules will be enforced. ***"
    }
    Write-Output "Current UTC/GMT time [$($currentTime.ToString("dddd, yyyy MMM dd HH:mm:ss"))] will be checked against schedules"
    
    foreach ($SubscriptionId in $subscriptionIds) {
        Write-Output "Processing subscription: $SubscriptionId"
        Set-AzContext -SubscriptionId $SubscriptionId

        $resourceManagerVMList = @(Get-AzVM -Status | Sort-Object Name)
 
        Write-Output "Found [$($resourceManagerVMList.Count)] virtual machines in the subscription [$SubscriptionId]"
 
        foreach ($vm in $resourceManagerVMList) {
            $schedule = $null
 
            if ($vm.Tags.$TagName) {
                $schedule = $vm.Tags.$TagName
                Write-Output "[$($vm.Name)]: Found schedule tag with value: $schedule"
            }
            else {
                Write-Output "[$($vm.Name)]: Not tagged for shutdown. Skipping this VM."
                continue
            }
 
            if ($schedule -eq $null) {
                Write-Output "[$($vm.Name)]: Failed to get tagged schedule for virtual machine. Skipping this VM."
                continue
            }
 
            $timeRangeList = @($schedule -split "," | ForEach-Object { $_.Trim() })
            
            $scheduleMatched = $false
            $matchedSchedule = $null
            foreach ($entry in $timeRangeList) {
                if ((CheckScheduleEntry -TimeRange $entry) -eq $true) {
                    $scheduleMatched = $true
                    $matchedSchedule = $entry
                    break
                }
            }
 
            if ($scheduleMatched) {
                Write-Output "[$($vm.Name)]: Current time [$currentTime] falls within the scheduled shutdown range [$matchedSchedule]"
                AssertVirtualMachinePowerState -VirtualMachine $vm -DesiredState "StoppedDeallocated" -Simulate $Simulate
            }
            else {
                Write-Output "[$($vm.Name)]: Current time falls outside of all scheduled shutdown ranges."
                AssertVirtualMachinePowerState -VirtualMachine $vm -DesiredState "Started" -Simulate $Simulate
            }
        }
    }
 
    Write-Output "Finished processing virtual machine schedules"
}
catch {
    $errorMessage = $_.Exception.Message
    throw "Unexpected exception: $errorMessage"
}
finally {
    Write-Output "Script finished (Duration: $(("{0:hh\:mm\:ss}" -f ((Get-Date).ToUniversalTime() - $currentTime))))"
}
