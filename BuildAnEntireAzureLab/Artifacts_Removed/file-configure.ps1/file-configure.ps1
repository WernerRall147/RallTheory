$folders = "C:\downloads", "C:\moonshoot", "C:\files", "C:\files\aanderson", "C:\files\bblackford", "C:\files\ccassidy", "C:\files\ddavis", "C:\files\eevans", "C:\files\ffranklin", "C:\files\ggarrison", "C:\files\hharris", "C:\files\iiverson", "C:\files\jjackson"
$filesToDownload = "SQLServer2017-SSEI-Expr.exe", "c-moonshoot.zip", "c-files-aanderson.zip", "c-files-bblackford.zip", "c-files-ccassidy.zip", "c-files-ddavis.zip", "c-files-eevans.zip", "c-files-ffranklin.zip", "c-files-ggarrison.zip", "c-files-hharris.zip", "c-files-iiverson.zip", "c-files-jjackson.zip"
$people =   [tuple]::Create("Alice", "Anderson", "aanderson"),
            [tuple]::Create("Bruce", "Blackford", "bblackford"),
            [tuple]::Create("Chris", "Cassidy", "ccassidy"),
            [tuple]::Create("Darren", "Davis", "ddavis"),
            [tuple]::Create("Eleanor", "Evans", "eevans"),
            [tuple]::Create("Fred", "Franklin", "ffranklin"),
            [tuple]::Create("Gary", "Garrison", "ggarrison"),
            [tuple]::Create("Hugh", "Harris", "hharris"),
            [tuple]::Create("Irma", "Iverson", "iiverson"),
            [tuple]::Create("Jane", "Jackson", "jjackson")

$perms = [tuple]::Create("Administrators", "FullControl", "ThisFolderSubfoldersAndFiles"),
         [tuple]::Create("SYSTEM", "FullControl", "ThisFolderSubfoldersAndFiles"),
         [tuple]::Create("Creator Owner", "FullControl", "ThisFolderSubfoldersAndFiles"),
         [tuple]::Create("Authenticated Users", "ReadAndExecute, ListDirectory, Read", "ThisFolderOnly")
 
configuration FILE 
{
    param
    (
        [Parameter(Mandatory)][PSCredential]$DomainCred,
        [Parameter(Mandatory)][String]$DomainName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xTimeZone
    Import-DscResource -ModuleName xSystemSecurity
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xSmbShare
    Import-DscResource -ModuleName cNtfsAccessControl
    Import-DscResource -ModuleName xActiveDirectory
    
    node "localhost"
    {
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
            AllowModuleOverwrite = $true
        }
        xTimeZone PacificTZ
        {
            IsSingleInstance = 'Yes'
            TimeZone = 'Pacific Standard Time'
        }
        xIEEsc DisableIEESCAdmins
        {
            UserRole = 'Administrators'
            isEnabled = $false
        }
        xIEEsc DisableIEESCUsers
        {
            UserRole = 'Users'
            isEnabled = $false
        }
        xComputer JoinDomain
        {
            Name = "FILE"
            DomainName = $DomainName
            Credential = $DomainCred
        }
        WindowsFeature ADDSTools            
        {             
            Ensure = "Present"             
            Name = "RSAT-ADDS"             
        }

        #Create Folders
        $num = 0;
        foreach ($folder in $folders)
        {
            $num++;
            File "CreateFolders$num"
            {
                Ensure = "Present"
                Type = "Directory"
                DestinationPath = $folder
            }
        }

        #Download files
        $num = 0;
        foreach ($file in $filesToDownload)
        {
            $num++;
            xRemoteFile "DownloadFile$num"
            {
                Uri = "https://mitbootcamp.blob.core.windows.net/labs/$file"
                DestinationPath = "C:\downloads\$file"
                MatchSource = $true
            }
        }

        #Extract Files
        foreach ($file in $filesToDownload)
        {
            if ($file.ToLower().EndsWith(".zip"))
            {
                Archive "ExtractFile$file.GetHashCode()"
                {
                    Ensure = "Present"
                    Path = "C:\downloads\$file"
                    Destination = (($file.Replace("c-", "C:\")).Replace("-", "\")).Replace(".zip", "\")
                }
            }
        }

        #Create Moonshoot Share
        xSmbShare Moonshoot
        {
            Ensure = "Present"
            Name = "moonshoot"
            Path = "C:\Moonshoot"
            FullAccess = "CORP\ProjectMoonshoot"
            ReadAccess = "CORP\Domain Users"
        }

        #Create Home Folder Root Share
        xSmbShare HomeFolder
        {
            Ensure = "Present"
            Name = "home$"
            Path = "C:\files"
            FullAccess = "Administrators", "Authenticated Users", "SYSTEM"
        }

        cNtfsPermissionsInheritance HomePermsInheritance
        {
            Path = "C:\files"
            Enabled = $false
            PreserveInherited = $false
        }

        #Set Permissions on Home Folder Root
        foreach ($perm in $perms)
        {
            cNtfsPermissionEntry "HomePerms$($perm.GetHashCode().ToString())"
            {
                Ensure = "Present"
                Path = "C:\files"
                Principal = $perm.Item1
                AccessControlInformation = cNtfsAccessControlInformation
                {
                    AccessControlType = "Allow"
                    FileSystemRights = $perm.Item2
                    Inheritance = $perm.Item3
                }
            }
        }

        #Create Personal Shares
        foreach ($person in $people)
        {
            cNtfsPermissionEntry "UserPerms$($person.GetHashCode().ToString())"
            {
                Ensure = "Present"
                Path = "C:\files\$($person.Item3)"
                Principal = "CORP\$($person.Item3)"
                AccessControlInformation = cNtfsAccessControlInformation
                {
                    AccessControlType = "Allow"
                    FileSystemRights = "FullControl"
                }
            }

            xADUser "UpdateAD$($person.GetHashCode().ToString())"
            {
                DomainName = $DomainName
                UserName = $person.Item3
                DomainController = "ad"
                DomainAdministratorCredential = $DomainCred
                HomeDrive = "H:"
                HomeDirectory = "\\file\home$\$($person.Item3)"
            }
        }

        Script InstallSQLExpress
        {
            SetScript = { 
                c:\downloads\SQLServer2017-SSEI-Expr.exe /IACCEPTSQLSERVERLICENSETERMS /Quiet /Action=Install
            }
            TestScript = { Test-Path "C:\Program Files\Microsoft SQL Server\140" }
            GetScript = { }
        }
    }
}