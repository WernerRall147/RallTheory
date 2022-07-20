<#

Name: deploy-mibclab.ps1
Version: 5.4
Author: Ken St. Cyr <ken.stcyr@microsoft.com>
Modified 20200913: Werner Rall <weral@microsoft.com>

Description:
This script uses an ARM template to deploy the lab environment for the Modern IT Boot Camp into an Azure subscription.

20200913: The AzureRM modules were failing. They were all replaced with the new Az modules.

#>

param (
    [Parameter(Mandatory = $true)]
    [string]
    $LabPassword,

    [Parameter(Mandatory = $true)]
    [string]
    $AzureAccountName,

    [Parameter(Mandatory = $false)]
    [switch]
    $ShutdownVMs,

    [Parameter(Mandatory = $false)]
    [string]
    $SubscriptionId
)

# Define deployment variables
$location = "eastus"
$rgname = "mitbc"
$deployment = "mitbc-deployment"
$template = (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition) + "\mit-bootcamp.json"
$securePassword = $LabPassword | ConvertTo-SecureString -AsPlainText -Force

function Main()
{
    # Check if the Password has been pwned
    if (PasswordPwned $LabPassword)
    {
        Write-Host "`r`nERROR: The password you're attempting to use is known to have been compromised. Please try again with a stronger password.`r`n" -ForegroundColor Red
        Exit
    }

    # Sign in to Azure Subscription
    while ((Get-AzContext -ErrorAction SilentlyContinue).Account.Id -ne $AzureAccountName)
    {
        Write-Host "`r`nYou are not currently signed into Azure with the account name that you provided. Sign in with the appropriate account in order to continue." -ForegroundColor Green
        pause
        Login-AzAccount | Out-Null
    }

    $subs = Get-AzSubscription -WarningAction SilentlyContinue
    if ($subs.Count -eq 0)
    {
        Write-Host "`r`nThe account you're attempting to use does not have any Azure subscriptions associated with it. Please run this script again with an account that has a valid Azure subscription." -ForegroundColor Yellow
        Exit
    }

    if (($subs.Count -gt 1) -and ($SubscriptionId.Length -gt 0))
    {
        Set-AzContext -Subscription $SubscriptionId
    }
    else
    {
        if ($subs.Count -gt 1)
        {
            Write-Host "`r`nYou have multiple subscriptions associated with your Azure account. Which one would you like to use?"
            for ($i = 1; $i -le $subs.Count; $i++)
            {
                Write-Host "$i)" -NoNewline -ForegroundColor Green
                Write-Host " $($subs[$($i-1)].Name) - " -NoNewline -ForegroundColor White
                Write-Host $subs[$i-1].SubscriptionId -ForegroundColor Cyan
            }
            Write-Host "Enter a Number [1 - $($subs.Count)]: " -ForegroundColor Green -NoNewline
            $sel = Read-Host
            $subs[$sel - 1] | Set-AzContext | Out-Null
        }
    }

    # Create Resource Group
    New-AzResourceGroup -Name $rgname -Location $location -Force

    $existing_deployment = Get-AzResourceGroupDeployment -ResourceGroupName $rgname -DeploymentName $deployment -ErrorAction SilentlyContinue
    if ($null -ne $existing_deployment) { $Nonce = $existing_deployment.Parameters.nonce.Value; }
    if ($Nonce.Length -eq 0) { $Nonce = Get-Random -Minimum 100000000 -Maximum 999999999; }

    # Deploy Resources
    $additionalParameters = New-Object -TypeName Hashtable
    $additionalParameters['AdminPassword'] = $securePassword
    $additionalParameters['Nonce'] = $Nonce

    New-AzResourceGroupDeployment -Name $deployment -ResourceGroupName $rgname -TemplateFile $template @additionalParameters -Force

    # Shut Down the VMs
    if ($ShutdownVMs -eq $true)
    {
        while ((Get-AzResourceGroupDeployment -ResourceGroupName $rgname).ProvisioningState -eq "Running")
        {
            Start-Sleep 30
        }
        Get-AzResource -ResourceGroupName $rgname -ResourceType "Microsoft.Compute/virtualMachines" | Stop-AzVM –Force
    }
}

function PasswordPwned($pwdToTest)
{
    $hasher = New-Object -TypeName "System.Security.Cryptography.SHA1CryptoServiceProvider"
    $encoding = [System.Text.Encoding]::UTF8
    $hash = ($hasher.ComputeHash($encoding.GetBytes($pwdToTest)) | ForEach-Object { "{0:X2}" -f $_ }) -join ""
    $first_five = $hash.Substring(0, 5)
    $remainder_hash = $hash.Substring(5)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $apiURL = "https://api.pwnedpasswords.com/range/" + $first_five
    $hashes = (Invoke-WebRequest $apiURL -UseBasicParsing).Content
    return $hashes.Contains($remainder_hash)
}


Main