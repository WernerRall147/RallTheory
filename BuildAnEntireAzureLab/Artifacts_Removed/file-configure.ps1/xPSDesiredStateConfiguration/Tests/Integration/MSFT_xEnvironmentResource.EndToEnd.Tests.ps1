<#
    Please note that some of these tests depend on each other.
    They must be run in the order given - if one test fails, subsequent tests may
    also fail.
#>
$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

# Import CommonTestHelper for Enter-DscResourceTestEnvironment, Exit-DscResourceTestEnvironment
$script:testsFolderFilePath = Split-Path $PSScriptRoot -Parent
$script:commonTestHelperFilePath = Join-Path -Path $testsFolderFilePath -ChildPath 'CommonTestHelper.psm1'
Import-Module -Name $commonTestHelperFilePath

if (Test-SkipContinuousIntegrationTask -Type 'Integration')
{
    return
}

$script:testEnvironment = Enter-DscResourceTestEnvironment `
    -DscResourceModuleName 'xPSDesiredStateConfiguration' `
    -DscResourceName 'MSFT_xEnvironmentResource' `
    -TestType 'Integration'

try
{
    Describe 'xEnvironmentResouce Integration Tests - with both Targets specified (default)' {
        BeforeAll {
            $script:testEnvironmentVarName = 'TestEnvironmentVariableName'
            $script:testPathEnvironmentVarName = 'TestPathEnvironmentVariableName'
            $script:machineEnvironmentRegistryPath = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'

            $script:testValue = 'InitialTestValue'
            $script:newTestValue = 'NewTestValue'

            $script:configFile = Join-Path -Path $PSScriptRoot -ChildPath 'MSFT_xEnvironmentResource.config.ps1'
        }

        AfterAll {
            # Remove variables from the process:
            [System.Environment]::SetEnvironmentVariable($script:testEnvironmentVarName, $null)
            [System.Environment]::SetEnvironmentVariable($script:testPathEnvironmentVarName, $null)

            # Remove variables from machine:
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName
            }
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName
            }
        }

        Context "Should create the environment variable $script:testEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Create'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            # Ensure the environment variable doesn't exist

            # Remove variable from the process:
            [System.Environment]::SetEnvironmentVariable($script:testEnvironmentVarName, $null)

            # Remove variable from machine:
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName
            }

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value $script:testValue `
                                         -Ensure 'Present' `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $script:testValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should update environment variable $script:testEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Update'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value $script:newTestValue `
                                         -Ensure 'Present' `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $script:newTestValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context 'Should not remove environment variable when value is different than what is already set' {
            $configurationName = 'MSFT_xEnvironmentResource_NonRemove'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value 'otherValue' `
                                         -Ensure 'Absent' `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $script:newTestValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should remove environment variable $script:testEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Remove'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value $null `
                                         -Ensure 'Absent' `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $null
               $currentConfig.Ensure | Should -Be 'Absent'
            }
        }

        Context "Should create the path environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Create_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            # Ensure the environment variable doesn't exist

            # Remove variable from the process:
            [System.Environment]::SetEnvironmentVariable($script:testPathEnvironmentVarName, $null)

            # Remove variable from machine:
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName
            }

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $script:testValue `
                                         -Ensure 'Present' `
                                         -Path $true `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $script:testValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should update environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Update_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $expectedValue = $script:testValue + ';' + $script:newTestValue

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $script:newTestValue `
                                         -Ensure 'Present' `
                                         -Path $true `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $expectedValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context 'Should not remove environment variable when value is different than what is already set' {
            $configurationName = 'MSFT_xEnvironmentResource_NonRemove_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $expectedValue = $script:testValue + ';' + $script:newTestValue

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value 'otherValue' `
                                         -Ensure 'Absent' `
                                         -Path $true `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $expectedValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should remove only one value from environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_PartialRemove_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $script:testValue `
                                         -Ensure 'Absent' `
                                         -Path $true `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $script:newTestValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should remove the environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Remove_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $null `
                                         -Ensure 'Absent' `
                                         -Path $true `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $null
               $currentConfig.Ensure | Should -Be 'Absent'
            }
        }
    }

    Describe 'xEnvironmentResouce Integration Tests - only Process Target specified' {
        BeforeAll {
            $script:testEnvironmentVarName = 'TestProcessEnvironmentVariableName'
            $script:testPathEnvironmentVarName = 'TestProcessPathEnvironmentVariableName'

            $script:testValue = 'InitialProcessTestValue'
            $script:newTestValue = 'NewProcessTestValue'

            $script:configFile = Join-Path -Path $PSScriptRoot -ChildPath 'MSFT_xEnvironmentResource.config.ps1'
        }

        AfterAll {
            # Remove variables from the process:
            [System.Environment]::SetEnvironmentVariable($script:testEnvironmentVarName, $null)
            [System.Environment]::SetEnvironmentVariable($script:testPathEnvironmentVarName, $null)

            # Remove variables from machine (these shouldn't have been set):
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName
            }
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName
            }
        }

        Context "Should create the environment variable $script:testEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Create'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            # Ensure the environment variable doesn't exist

            # Remove variable from the process:
            [System.Environment]::SetEnvironmentVariable($script:testEnvironmentVarName, $null)

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value $script:testValue `
                                         -Ensure 'Present' `
                                         -Target @('Process') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $script:testValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should update environment variable $script:testEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Update'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value $script:newTestValue `
                                         -Ensure 'Present' `
                                         -Target @('Process') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $script:newTestValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context 'Should not remove environment variable when value is different than what is already set' {
            $configurationName = 'MSFT_xEnvironmentResource_NonRemove'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value 'otherValue' `
                                         -Ensure 'Absent' `
                                         -Target @('Process') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $script:newTestValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should remove environment variable $script:testEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Remove'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value $null `
                                         -Ensure 'Absent' `
                                         -Target @('Process') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $null
               $currentConfig.Ensure | Should -Be 'Absent'
            }
        }

        Context "Should create the path environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Create_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            # Ensure the environment variable doesn't exist

            # Remove variable from the process:
            [System.Environment]::SetEnvironmentVariable($script:testPathEnvironmentVarName, $null)

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $script:testValue `
                                         -Ensure 'Present' `
                                         -Path $true `
                                         -Target @('Process') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $script:testValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should update environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Update_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $expectedValue = $script:testValue + ';' + $script:newTestValue

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $script:newTestValue `
                                         -Ensure 'Present' `
                                         -Path $true `
                                         -Target @('Process') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $expectedValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context 'Should not remove environment variable when value is different than what is already set' {
            $configurationName = 'MSFT_xEnvironmentResource_NonRemove_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $expectedValue = $script:testValue + ';' + $script:newTestValue

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value 'otherValue' `
                                         -Ensure 'Absent' `
                                         -Path $true `
                                         -Target @('Process') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $expectedValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should remove only one value from environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_PartialRemove_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $script:testValue `
                                         -Ensure 'Absent' `
                                         -Path $true `
                                         -Target @('Process') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $script:newTestValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should remove the environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Remove_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $null `
                                         -Ensure 'Absent' `
                                         -Path $true `
                                         -Target @('Process') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $null
               $currentConfig.Ensure | Should -Be 'Absent'
            }
        }
    }

    Describe 'xEnvironmentResouce Integration Tests - only Machine Target specified' {
        BeforeAll {
            $script:testEnvironmentVarName = 'TestMachineEnvironmentVariableName'
            $script:testPathEnvironmentVarName = 'TestMachinePathEnvironmentVariableName'

            $script:testValue = 'InitialMachineTestValue'
            $script:newTestValue = 'NewMachineTestValue'

            $script:configFile = Join-Path -Path $PSScriptRoot -ChildPath 'MSFT_xEnvironmentResource.config.ps1'
        }

        AfterAll {
            # Remove variables from the process (these shouldn't have been set):
            [System.Environment]::SetEnvironmentVariable($script:testEnvironmentVarName, $null)
            [System.Environment]::SetEnvironmentVariable($script:testPathEnvironmentVarName, $null)

            # Remove variables from machine:
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName
            }
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName
            }
        }

        Context "Should create the environment variable $script:testEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Create'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            # Ensure the environment variable doesn't exist:

            # Remove variable from machine:
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testEnvironmentVarName
            }

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value $script:testValue `
                                         -Ensure 'Present' `
                                         -Target @('Machine') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $script:testValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should update environment variable $script:testEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Update'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value $script:newTestValue `
                                         -Ensure 'Present' `
                                         -Target @('Machine') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $script:newTestValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context 'Should not remove environment variable when value is different than what is already set' {
            $configurationName = 'MSFT_xEnvironmentResource_NonRemove'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value 'otherValue' `
                                         -Ensure 'Absent' `
                                         -Target @('Machine') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $script:newTestValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should remove environment variable $script:testEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Remove'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testEnvironmentVarName `
                                         -Value $null `
                                         -Ensure 'Absent' `
                                         -Target @('Machine') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testEnvironmentVarName
               $currentConfig.Value | Should -Be $null
               $currentConfig.Ensure | Should -Be 'Absent'
            }
        }

        Context "Should create the path environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Create_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            # Ensure the environment variable doesn't exist:

            # Remove variable from machine:
            if (Get-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName -ErrorAction 'SilentlyContinue')
            {
                Remove-ItemProperty -Path $script:machineEnvironmentRegistryPath -Name $script:testPathEnvironmentVarName
            }

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $script:testValue `
                                         -Ensure 'Present' `
                                         -Path $true `
                                         -Target @('Machine') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $script:testValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should update environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Update_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $expectedValue = $script:testValue + ';' + $script:newTestValue

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $script:newTestValue `
                                         -Ensure 'Present' `
                                         -Path $true `
                                         -Target @('Machine') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $expectedValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context 'Should not remove environment variable when value is different than what is already set' {
            $configurationName = 'MSFT_xEnvironmentResource_NonRemove_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $expectedValue = $script:testValue + ';' + $script:newTestValue

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value 'otherValue' `
                                         -Ensure 'Absent' `
                                         -Path $true `
                                         -Target @('Machine') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $expectedValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should remove only one value from environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_PartialRemove_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $script:testValue `
                                         -Ensure 'Absent' `
                                         -Path $true `
                                         -Target @('Machine') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $script:newTestValue
               $currentConfig.Ensure | Should -Be 'Present'
            }
        }

        Context "Should remove the environment variable $script:testPathEnvironmentVarName" {
            $configurationName = 'MSFT_xEnvironmentResource_Remove_Path'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            It 'Should compile without throwing' {
                {
                    . $script:configFile -ConfigurationName $configurationName
                    & $configurationName -Name $script:testPathEnvironmentVarName `
                                         -Value $null `
                                         -Ensure 'Absent' `
                                         -Path $true `
                                         -Target @('Machine') `
                                         -OutputPath $configurationPath `
                                         -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -ErrorAction 'Stop' -Wait -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -ErrorAction 'Stop' } | Should -Not -Throw
            }

            It 'Should return the correct configuration' {
               $currentConfig = Get-DscConfiguration -ErrorAction 'Stop'
               $currentConfig.Name | Should -Be $script:testPathEnvironmentVarName
               $currentConfig.Value | Should -Be $null
               $currentConfig.Ensure | Should -Be 'Absent'
            }
        }
    }
}
finally
{
    Exit-DscResourceTestEnvironment -TestEnvironment $script:testEnvironment
}
