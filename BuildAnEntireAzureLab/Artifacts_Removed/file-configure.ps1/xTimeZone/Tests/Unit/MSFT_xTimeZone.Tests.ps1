$script:DSCModuleName = 'xTimeZone'
$script:DSCResourceName = 'MSFT_xTimeZone'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'MSFT_xTimeZone'

        Describe "$($script:DSCResourceName) MOF single instance schema" {
            It 'Should have mandatory IsSingleInstance parameter and one other parameter' {
                $timeZoneResource = Get-DscResource -Name xTimeZone

                $timeZoneResource.Properties.Where{
                    $_.Name -eq 'IsSingleInstance'
                }.IsMandatory | Should Be $true

                $timeZoneResource.Properties.Where{
                    $_.Name -eq 'IsSingleInstance'
                }.Values | Should Be 'Yes'
            }
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Mock `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Pacific Standard Time' }

            $TimeZone = Get-TargetResource `
                -TimeZone 'Pacific Standard Time' `
                -IsSingleInstance 'Yes' `
                -Verbose

            It 'Should return hashtable with Key TimeZone' {
                $TimeZone.ContainsKey('TimeZone') | Should Be $true
            }

            It 'Should return hashtable with Value that matches "Pacific Standard Time"' {
                $TimeZone.TimeZone = 'Pacific Standard Time'
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Mock `
                -CommandName Set-TimeZoneId

            Mock `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Eastern Standard Time' }

            It 'Call Set-TimeZoneId' {
                Set-TargetResource `
                    -TimeZone 'Pacific Standard Time' `
                    -IsSingleInstance 'Yes' `
                    -Verbose

                Assert-MockCalled `
                    -CommandName Set-TimeZoneId `
                    -Exactly 1
            }

            It 'Should not call Set-TimeZoneId when Current TimeZone already set to desired State' {
                $SystemTimeZone = Get-TargetResource `
                    -TimeZone 'Eastern Standard Time' `
                    -IsSingleInstance 'Yes' `
                    -Verbose

                Set-TargetResource `
                    -TimeZone $SystemTimeZone.TimeZone `
                    -IsSingleInstance 'Yes' `
                    -Verbose

                Assert-MockCalled `
                    -CommandName Set-TimeZoneId `
                    -Scope It `
                    -Exactly 0
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Mock `
                -ModuleName TimeZoneDsc.Common `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Pacific Standard Time' }

            It 'Should return true when Test is passed Time Zone thats already set' {
                Test-TargetResource `
                    -TimeZone 'Pacific Standard Time' `
                    -IsSingleInstance 'Yes' `
                    -Verbose | Should Be $true
            }

            It 'Should return false when Test is passed Time Zone that is not set' {
                Test-TargetResource `
                    -TimeZone 'Eastern Standard Time' `
                    -IsSingleInstance 'Yes' `
                    -Verbose | Should Be $false
            }

        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
