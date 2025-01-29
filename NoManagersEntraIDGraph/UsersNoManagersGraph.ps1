<#
.SYNOPSIS
    Checks whether users in Azure AD have a manager, retrieves the manager's DisplayName,
    and also includes the user's UPN and Mail.

.DESCRIPTION
    1) Connect to Microsoft Graph.
    2) Fetch all users (Id, DisplayName, UserPrincipalName, Mail).
    3) For each user:
       - Check if they have a manager (Get-MgUserManager).
       - If yes, retrieve the manager’s user object (Get-MgUser) to get the manager’s DisplayName.
    4) Print out the user’s DisplayName, UPN, Mail, HasManager, and ManagerName.

.NOTES
    Author: [Your Name]
    Date:   [Date]
#>

# ------------------------ Script Start ------------------------
Write-Host "Starting script to check for user managers in Azure AD..." -ForegroundColor Green

# 1. Connect to Microsoft Graph (optional: -NoWelcome to hide banner)
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

# Use a stopwatch to measure how long each major part of the script takes
$totalScriptStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$sectionStopwatch     = [System.Diagnostics.Stopwatch]::StartNew()

# 2. Fetch all users (explicitly request multiple properties: Id, DisplayName, UPN, Mail)
Write-Host "Fetching all users from Azure AD..." -ForegroundColor Cyan
$allUsers = Get-MgUser -All:$true -Property "Id","DisplayName","UserPrincipalName","Mail"

$sectionStopwatch.Stop()
Write-Host ("[Fetch Users] Time Elapsed: {0} seconds." -f ($sectionStopwatch.Elapsed.TotalSeconds)) -ForegroundColor Yellow
Write-Host "Total users retrieved: $($allUsers.Count)" -ForegroundColor Magenta

# 3. For each user, check manager
Write-Host "Checking managers for each user..." -ForegroundColor Cyan
$sectionStopwatch.Restart()

$results = @()
$count   = 0
$total   = $allUsers.Count

foreach ($user in $allUsers) {
    $count++

    # Show progress
    Write-Host ("Processing user {0} of {1}: {2}" -f $count, $total, $user.DisplayName) -ForegroundColor DarkGray

    # Skip if user.Id is null or empty
    if ([string]::IsNullOrWhiteSpace($user.Id)) {
        Write-Warning "Skipping user $($user.DisplayName). The user object does not have a valid Id."
        continue
    }

    # 3a. Retrieve the manager reference
    $managerRef = Get-MgUserManager -UserId $user.Id -ErrorAction SilentlyContinue

    # 3b. Determine if manager was found
    $hasManager = $managerRef -ne $null
    $managerName = $null

    # 3c. If manager exists, do a second call to get manager’s details
    if ($hasManager -and $managerRef.Id) {
        # Get the manager's user object to retrieve the display name
        $managerUser = Get-MgUser -UserId $managerRef.Id -ErrorAction SilentlyContinue -Property "DisplayName"

        if ($managerUser -and $managerUser.DisplayName) {
            $managerName = $managerUser.DisplayName
        }
    }

    # Collect results
    $results += [PSCustomObject]@{
        UserDisplayName = $user.DisplayName
        UserUPN         = $user.UserPrincipalName
        UserMail        = $user.Mail
        HasManager      = $hasManager
        ManagerName     = $managerName
    }
}

$sectionStopwatch.Stop()
Write-Host ("[Check Managers] Time Elapsed: {0} seconds." -f ($sectionStopwatch.Elapsed.TotalSeconds)) -ForegroundColor Yellow

# 4. Output results
Write-Host "Summary of results:" -ForegroundColor Cyan
$results | Format-Table UserDisplayName, UserUPN, UserMail, HasManager, ManagerName

# 5. Stop total script stopwatch
$totalScriptStopwatch.Stop()
Write-Host ("[Total Script Time] Elapsed: {0} seconds." -f ($totalScriptStopwatch.Elapsed.TotalSeconds)) -ForegroundColor Green

Write-Host "Script completed." -ForegroundColor Green
# ------------------------ Script End ------------------------

$results | Export-Csv -Path .\UsersManagers.csv -NoTypeInformation
