<#PSScriptInfo
.VERSION 1.0.0
.GUID c0a8626d-0f4f-469d-8f20-b79f860edc09
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/xPSDesiredStateConfiguration/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/xPSDesiredStateConfiguration
.ICONURI
.EXTERNALMODULEDEPENDENCIES NetworkingDsc, xPSDesiredStateConfiguration
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
#>
<#
    .SYNOPSIS
        Configures a DSC Pull Server with enhanced security and a firewall rule
        to allow extenal connections.

    .DESCRIPTION
        The Sample_xDscWebServiceRegistration configuration sets up a DSC pull
        server that is capable for client nodes to register with it and
        retrieve configuration documents with configuration names instead of
        configuration id.

        Prerequisite: 1 - Install a certificate in 'CERT:\LocalMachine\MY\' store
                          For testing environments, you could use a self-signed
                          certificate. (New-SelfSignedCertificate cmdlet could
                          generate one for you). For production environments, you
                          will need a certificate signed by valid CA. Registration
                          only works over https protocols. So to use registration
                          feature, a secure pull server setup with certificate is
                          necessary.
                      2 - To configure a Firewall Rule (Exception) to allow external
                          connections the [NetworkingDsc](https://github.com/PowerShell/NetworkingDsc)
                          DSC module is required.

    .PARAMETER NodeName
        The name of the node being configured as a DSC Pull Server.

    .PARAMETER CertificateThumbPrint
        Certificate thumbprint for creating an HTTPS endpoint. Use
        "AllowUnencryptedTraffic" for setting up a non SSL based endpoint.

    .PARAMETER RegistrationKey
        This key will be used by client nodes as a shared key to authenticate
        during registration. This should be a string with enough entropy
        (randomness) to protect the registration of clients to the pull server.
        The example creates a new GUID for the registration key.

    .PARAMETER Port
        The TCP port on which the Pull Server will listen for connections

    .EXAMPLE
        $thumbprint = (New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My).Thumbprint
        $registrationKey = [System.Guid]::NewGuid()

        Sample_xDscWebServiceRegistration -RegistrationKey $registrationkey -CertificateThumbPrint $thumbprint
#>
Configuration Sample_xDscWebServiceRegistration
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $CertificateThumbPrint,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RegistrationKey,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [System.UInt16]
        $Port = 8080
    )

    Import-DscResource -ModuleName NetworkingDsc
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration

    Node $NodeName
    {
        WindowsFeature DSCServiceFeature
        {
            Ensure = 'Present'
            Name   = 'DSC-Service'
        }

        xDscWebService PSDSCPullServer
        {
            Ensure                       = 'Present'
            EndpointName                 = 'PSDSCPullServer'
            Port                         = $Port
            PhysicalPath                 = "$env:SystemDrive\inetpub\PSDSCPullServer"
            CertificateThumbPrint        = $CertificateThumbPrint
            ModulePath                   = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath            = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                        = 'Started'
            DependsOn                    = '[WindowsFeature]DSCServiceFeature'
            RegistrationKeyPath          = "$env:PROGRAMFILES\WindowsPowerShell\DscService"
            AcceptSelfSignedCertificates = $true
            Enable32BitAppOnWin64        = $false
            UseSecurityBestPractices     = $true
            ConfigureFirewall            = $false
        }

        File RegistrationKeyFile
        {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents        = $RegistrationKey
        }

        Firewall PSDSCPullServerRule
        {
            Ensure      = 'Present'
            Name        = "DSC_PullServer_$Port"
            DisplayName = "DSC PullServer $Port"
            Group       = 'DSC PullServer'
            Enabled     = $true
            Action      = 'Allow'
            Direction   = 'InBound'
            LocalPort   = $Port
            Protocol    = 'TCP'
            DependsOn   = '[xDscWebService]PSDSCPullServer'
        }
    }
}
