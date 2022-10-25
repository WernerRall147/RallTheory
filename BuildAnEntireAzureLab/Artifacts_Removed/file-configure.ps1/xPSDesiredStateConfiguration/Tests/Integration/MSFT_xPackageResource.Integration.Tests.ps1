Import-Module "$PSScriptRoot\..\CommonTestHelper.psm1"

if (Test-SkipContinuousIntegrationTask -Type 'Integration')
{
    return
}

$script:testEnvironment = Enter-DscResourceTestEnvironment `
    -DscResourceModuleName 'xPSDesiredStateConfiguration' `
    -DscResourceName 'MSFT_xPackageResource' `
    -TestType 'Integration'
try
{
    Describe 'xPackage Integration Tests' {
        BeforeAll {
            Import-Module "$PSScriptRoot\..\MSFT_xPackageResource.TestHelper.psm1" -Force

            $script:testDirectoryPath = Join-Path -Path $PSScriptRoot -ChildPath 'MSFT_xPackageResourceTests'

            if (Test-Path -Path $script:testDirectoryPath)
            {
                Remove-Item -Path $script:testDirectoryPath -Recurse -Force | Out-Null
            }

            New-Item -Path $script:testDirectoryPath -ItemType 'Directory' | Out-Null

            $script:msiName = 'DSCSetupProject.msi'
            $script:msiLocation = Join-Path -Path $script:testDirectoryPath -ChildPath $script:msiName

            $script:packageName = 'DSCUnitTestPackage'
            $script:packageId = '{deadbeef-80c6-41e6-a1b9-8bdb8a05027f}'

            New-TestMsi -DestinationPath $script:msiLocation | Out-Null

            Clear-PackageCache | Out-Null
        }

        BeforeEach {
            Clear-PackageCache | Out-Null

            if (Test-PackageInstalledByName -Name $script:packageName)
            {
                Start-Process -FilePath 'msiexec.exe' -ArgumentList @("/x$script:packageId", '/passive') -Wait | Out-Null
                Start-Sleep -Seconds 1 | Out-Null
            }

            if (Test-PackageInstalledByName -Name $script:packageName)
            {
                throw 'Package could not be removed.'
            }
        }

        AfterAll {
            if (Test-Path -Path $script:testDirectoryPath)
            {
                Remove-Item -Path $script:testDirectoryPath -Recurse -Force | Out-Null
            }

            Clear-PackageCache | Out-Null

            if (Test-PackageInstalledByName -Name $script:packageName)
            {
                Start-Process -FilePath 'msiexec.exe' -ArgumentList @("/x$script:packageId", '/passive') -Wait | Out-Null
                Start-Sleep -Seconds 1 | Out-Null
            }

            if (Test-PackageInstalledByName -Name $script:packageName)
            {
                throw 'Test output will not be valid - package could not be removed.'
            }
        }

        It 'Install a .msi package' {
            $configurationName = 'EnsurePackageIsPresent'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            try
            {
                $configurationScriptText = @"
                Configuration $configurationName
                {
                    Import-DscResource -ModuleName xPSDesiredStateConfiguration

                    xPackage Package1
                    {
                        Path = '$script:msiLocation'
                        Ensure = "Present"
                        Name = '$script:packageName'
                        ProductId = '$script:packageId'
                    }
                }
"@
                .([System.Management.Automation.ScriptBlock]::Create($configurationScriptText))

                & $configurationName -OutputPath $configurationPath

                Start-DscConfiguration -Path $configurationPath -Wait -Force

                Test-PackageInstalledByName -Name $script:packageName | Should -Be $true
            }
            finally
            {
                if (Test-Path -Path $configurationPath)
                {
                    Remove-Item -Path $configurationPath -Recurse -Force
                }
            }
        }
    }
}
finally
{
    Exit-DscResourceTestEnvironment -TestEnvironment $script:testEnvironment
}
