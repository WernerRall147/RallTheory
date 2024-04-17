param (


 [Parameter(Mandatory=$true)]  
    [String] $SubscriptionId,

    [Parameter(Mandatory=$true)]  
    [String] $Action,

    [Parameter(Mandatory=$false)]  
    [String] $TagName,

    [Parameter(Mandatory=$false)]
    [String] $TagValue,

    [Parameter(Mandatory=$false)]
    [String] $SnapshotResourceGroupName

) 

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

try
{
    if ($TagName)
    {                    
        $instances = Get-AzResource -TagName $TagName -TagValue $TagValue -ResourceType "Microsoft.Compute/virtualMachines"
        
        if ($instances)
        {
            $resourceGroupsContent = @()
                                      
            foreach ($instance in $instances)
            {
                $instancePowerState = (((Get-AzVM -ResourceGroupName $($instance.ResourceGroupName) -Name $($instance.Name) -Status).Statuses.Code[1]) -replace "PowerState/", "")

                $resourceGroupContent = New-Object -Type PSObject -Property @{
                    "Resource group name" = $($instance.ResourceGroupName)
                    "Instance name" = $($instance.Name)
                    "Instance type" = (($instance.ResourceType -split "/")[0].Substring(10))
                    "Instance state" = ([System.Threading.Thread]::CurrentThread.CurrentCulture.TextInfo.ToTitleCase($instancePowerState))
                    $TagName = $TagValue
                }

                $resourceGroupsContent += $resourceGroupContent
            }
        }
        else
        {
            #Do nothing
        }
    }       
    else
    {
        $instances = Get-AzResource -ResourceType "Microsoft.Compute/virtualMachines"

        if ($instances)
        {
            $resourceGroupsContent = @() 
                  
            foreach ($instance in $instances)
            {
                $instancePowerState = (((Get-AzVM -ResourceGroupName $($instance.ResourceGroupName) -Name $($instance.Name) -Status).Statuses.Code[1]) -replace "PowerState/", "")

                $resourceGroupContent = New-Object -Type PSObject -Property @{
                    "Resource group name" = $($instance.ResourceGroupName)
                    "Instance name" = $($instance.Name)
                    "Instance type" = (($instance.ResourceType -split "/")[0].Substring(10))
                    "Instance state" = ([System.Threading.Thread]::CurrentThread.CurrentCulture.TextInfo.ToTitleCase($instancePowerState))
                }

                $resourceGroupsContent += $resourceGroupContent
            }
        }
        else
        {
            #Do nothing
        }
    }

    $resourceGroupsContent | Format-Table -AutoSize
}
catch
{
    Write-Error -Message $_.Exception
    throw $_.Exception    
}
## End of getting all virtual machines

$runningInstances = ($resourceGroupsContent | Where-Object {$_.("Instance state") -eq "Running" -or $_.("Instance state") -eq "Starting"})
$deallocatedInstances = ($resourceGroupsContent | Where-Object {$_.("Instance state") -eq "Deallocated" -or $_.("Instance state") -eq "Deallocating"})

## Updating virtual machines power state
if (($runningInstances) -and ($Action -eq "Yes"))
{
    Write-Output "--------------------------- Updating ---------------------------"
    Write-Output "Trying to stop virtual machines ..."

    try
    {
        $updateStatuses = @() 

        foreach ($runningInstance in $runningInstances)
        {                                    
            Write-Output "$($runningInstance.("Instance name")) is being snapshotted ..."

            $startTime = Get-Date -Format G

            # Get the VM
            $vm = Get-AzVM -ResourceGroupName $($runningInstance.("Resource group name")) -Name $($runningInstance.("Instance name"))

            # Get the source disk
            $sourceDisk = Get-AzDisk -ResourceGroupName $($runningInstance.("Resource group name")) -DiskName $vm.StorageProfile.OsDisk.Name

            # Define the snapshot
            $snapshotConfig = New-AzSnapshotConfig -SourceUri $sourceDisk.Id -Location $vm.Location -CreateOption Copy

            # Create the snapshot
            $null = New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName "$($runningInstance.("Instance name"))-snapshot" -ResourceGroupName $SnapshotResourceGroupName

            $endTime = Get-Date -Format G

            $updateStatus = New-Object -Type PSObject -Property @{
                "Resource group name" = $($runningInstance.("Resource group name"))
                "Instance name" = $($runningInstance.("Instance name"))
                "Snapshot start time" = $startTime
                "Snapshot end time" = $endTime
            }

            $updateStatuses += $updateStatus
        }

        $updateStatuses | Format-Table -AutoSize
    }
    catch
    {
        Write-Error -Message $_.Exception
        throw $_.Exception    
    }
}
else
{
    Write-Output "$runningInstances No selected virtual machines are running and can be snapshot."
}
#### End of updating virtual machines power state
