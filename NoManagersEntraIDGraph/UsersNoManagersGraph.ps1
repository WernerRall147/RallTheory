<#
.SYNOPSIS
    Fetches enabled member users from Azure AD, retrieves many properties, 
    checks for a manager, collects license details, and outputs them in CSV/table format.

.DESCRIPTION
    1) Connect to Microsoft Graph.
    2) Filter users: userType eq 'Member' AND accountEnabled eq true.
    3) Retrieve user properties: 
       - Basic info (DisplayName, UPN, Mail, etc.)
       - Additional info (Department, CompanyName, CreatedDateTime, EmployeeHireDate, 
         OnPremisesSamAccountName, SignInSessionsValidFromDateTime, AssignedLicenses, 
         AssignedPlans, LicenseAssignmentStates, OfficeLocation).
       - Optional custom extension (Sponsors).
    4) For each user:
       - If they have a manager, fetch manager's DisplayName.
       - Retrieve license details from Get-MgUserLicenseDetail.
       - Replace any empty property with "None".
    5) Output the results (Format-Table or CSV).

.NOTES
    Author: [Your Name]
    Date:   [Date]

    - Make sure you have installed Microsoft.Graph module: 
      Install-Module Microsoft.Graph -Scope CurrentUser
    - You need permissions: User.Read.All, Directory.Read.All, etc.
    - If "Sponsors" is not used in your tenant, remove references or adapt 
      for onPremisesExtensionAttributes or other custom properties.

    This script can be large/slow if you have many users because it calls 
    additional endpoints for manager references and license details.
#>

Write-Host "Starting script to check for user managers and extended properties in Azure AD..." -ForegroundColor Green

# 1) Connect to Microsoft Graph 
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

$totalScriptStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$sectionStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# 2) Filter to get enabled member users
Write-Host "Fetching filtered users (members, enabled) from Azure AD..." -ForegroundColor Cyan
$filter = "userType eq 'Member' and accountEnabled eq true"

# If you do not need the "Sponsors" extension property, remove it. If you have 
# a different extension property name, replace the string below.
# If using on-premises extension attributes (extensionAttribute1..15), 
# add "OnPremisesExtensionAttributes" and reference accordingly.
$extensionPropertyName = "extension_1234567890abcdef_Sponsors"

# We explicitly request these properties in a single call:
# - Basic: Id, DisplayName, UserPrincipalName, Mail
# - Profile: JobTitle, Department, CompanyName, EmployeeHireDate
# - Timestamps: CreatedDateTime, SignInSessionsValidFromDateTime
# - On-prem: OnPremisesSamAccountName
# - Licensing arrays: AssignedLicenses, AssignedPlans, LicenseAssignmentStates
# - Office info: OfficeLocation
# - Optional extension: $extensionPropertyName
$requestedProps = @(
    "Id",
    "DisplayName",
    "UserPrincipalName",
    "Mail",
    "JobTitle",
    "Department",
    "CompanyName",
    "CreatedDateTime",
    "EmployeeHireDate",
    "OnPremisesSamAccountName",
    "SignInSessionsValidFromDateTime",
    "AssignedLicenses",
    "AssignedPlans",
    "LicenseAssignmentStates",
    "OfficeLocation",
    $extensionPropertyName
)

$allUsers = Get-MgUser -All:$true `
                       -Filter $filter `
                       -Property $requestedProps

$sectionStopwatch.Stop()
Write-Host ("[Fetch Users] Time Elapsed: {0} seconds." -f ($sectionStopwatch.Elapsed.TotalSeconds)) -ForegroundColor Yellow
Write-Host "Total users retrieved (members, enabled): $($allUsers.Count)" -ForegroundColor Magenta

# 3) Check managers, gather LicenseDetails, build results
Write-Host "Processing each user for manager info, license details, and fields..." -ForegroundColor Cyan
$sectionStopwatch.Restart()

$results = @()
$count   = 0
$total   = $allUsers.Count

foreach ($user in $allUsers) {
    $count++
    Write-Host ("Processing user {0} of {1}: {2}" -f $count, $total, $user.DisplayName) -ForegroundColor DarkGray

    # Skip if user.Id is null or empty
    if ([string]::IsNullOrWhiteSpace($user.Id)) {
        Write-Warning "Skipping user $($user.DisplayName). The user object does not have a valid Id."
        continue
    }

    ### =========== 3a) Manager Reference =========== ###
    $managerRef = Get-MgUserManager -UserId $user.Id -ErrorAction SilentlyContinue
    $hasManager = $managerRef -ne $null
    $managerName = "None"  # default

    if ($hasManager -and $managerRef.Id) {
        $managerUser = Get-MgUser -UserId $managerRef.Id -Property "DisplayName" -ErrorAction SilentlyContinue
        if ($managerUser -and $managerUser.DisplayName) {
            $managerName = $managerUser.DisplayName
        }
    }

    ### =========== 3b) LicenseDetails =========== ###
    # Usually we want to see the SKU part numbers. 
    # This call returns a collection of license detail objects.
    $licenseDetailsData = Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction SilentlyContinue
    if ($licenseDetailsData) {
        # Concatenate SkuPartNumber into a semicolon-separated string
        $licenseDetails = ($licenseDetailsData | ForEach-Object { $_.SkuPartNumber }) -join ";"
    }
    else {
        $licenseDetails = "None"
    }

    ### =========== 3c) Convert property values, substituting "None" for empty =========== ###
    function ToNone($val) {
        if ([string]::IsNullOrWhiteSpace($val)) { return "None" }
        return $val
    }

    $displayName                    = ToNone $user.DisplayName
    $userPrincipalName              = ToNone $user.UserPrincipalName
    $mail                           = ToNone $user.Mail
    $jobTitle                       = ToNone $user.JobTitle
    $department                     = ToNone $user.Department
    $companyName                    = ToNone $user.CompanyName
    $createdDateTime                = if ($user.CreatedDateTime) { $user.CreatedDateTime } else { "None" }
    $employeeHireDate               = if ($user.EmployeeHireDate) { $user.EmployeeHireDate } else { "None" }
    $onPremisesSamAccountName       = ToNone $user.OnPremisesSamAccountName
    $signInSessionsValidFromDateTime= if ($user.SignInSessionsValidFromDateTime) { $user.SignInSessionsValidFromDateTime } else { "None" }
    $officeLocation                 = ToNone $user.OfficeLocation

    # These three licensing properties are arrays of objects. We can flatten them into a string.
    if ($user.AssignedLicenses) {
        $assignedLicenses = ($user.AssignedLicenses | ForEach-Object { $_.SkuId }) -join ";"
    } else {
        $assignedLicenses = "None"
    }

    if ($user.AssignedPlans) {
        $assignedPlans = ($user.AssignedPlans | ForEach-Object { $_.Service }) -join ";"
    } else {
        $assignedPlans = "None"
    }

    if ($user.LicenseAssignmentStates) {
        $licenseAssignmentStates = ($user.LicenseAssignmentStates | ForEach-Object { $_.SkuId }) -join ";"
    } else {
        $licenseAssignmentStates = "None"
    }

    # If you do not use a "Sponsors" extension, remove it
    $sponsorsValue = $user.$extensionPropertyName
    $sponsors = ToNone $sponsorsValue

    ### =========== 3d) Build result object =========== ###
    $results += [PSCustomObject]@{
        UserDisplayName                = $displayName
        UserUPN                        = $userPrincipalName
        UserMail                       = $mail
        JobTitle                       = $jobTitle
        Department                     = $department
        CompanyName                    = $companyName
        CreatedDateTime                = $createdDateTime
        EmployeeHireDate               = $employeeHireDate
        OnPremisesSamAccountName       = $onPremisesSamAccountName
        SignInSessionsValidFromDateTime= $signInSessionsValidFromDateTime
        OfficeLocation                 = $officeLocation
        Sponsors                       = $sponsors
        AssignedLicenses               = if ([string]::IsNullOrWhiteSpace($assignedLicenses)) { "None" } else { $assignedLicenses }
        AssignedPlans                  = if ([string]::IsNullOrWhiteSpace($assignedPlans)) { "None" } else { $assignedPlans }
        LicenseAssignmentStates        = if ([string]::IsNullOrWhiteSpace($licenseAssignmentStates)) { "None" } else { $licenseAssignmentStates }
        LicenseDetails                 = if ([string]::IsNullOrWhiteSpace($licenseDetails)) { "None" } else { $licenseDetails }
        HasManager                     = $hasManager
        ManagerName                    = $managerName
    }
}

$sectionStopwatch.Stop()
Write-Host ("[Process Users] Time Elapsed: {0} seconds." -f ($sectionStopwatch.Elapsed.TotalSeconds)) -ForegroundColor Yellow

# 4) Output results 
Write-Host "Summary of results (Members, Enabled):" -ForegroundColor Cyan
$results | Format-Table UserDisplayName,
                          UserUPN,
                          UserMail,
                          JobTitle,
                          Department,
                          CompanyName,
                          CreatedDateTime,
                          EmployeeHireDate,
                          OnPremisesSamAccountName,
                          SignInSessionsValidFromDateTime,
                          OfficeLocation,
                          Sponsors,
                          AssignedLicenses,
                          AssignedPlans,
                          LicenseAssignmentStates,
                          LicenseDetails,
                          HasManager,
                          ManagerName

# 5) Stop total script stopwatch
$totalScriptStopwatch.Stop()
Write-Host ("[Total Script Time] Elapsed: {0} seconds." -f ($totalScriptStopwatch.Elapsed.TotalSeconds)) -ForegroundColor Green

Write-Host "Script completed." -ForegroundColor Green

# 6) Optional: Export to CSV
$results | Export-Csv -Path .\UserManagerReport.csv -NoTypeInformation
