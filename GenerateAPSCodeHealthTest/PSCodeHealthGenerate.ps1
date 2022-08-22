Write-Host "Please Select the Directory you would like to run the PS Code Health"

Add-Type -AssemblyName 'System.Windows.Forms'
$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $directoryName = $dialog.SelectedPath
    Write-Host "Directory selected is $directoryName"
}

$Params = @{Path="$directoryName"; TestsPath='.\Tests\Unit\'; Recurse=$True}
$HealthReport = Invoke-PSCodeHealth @Params -HtmlReportPath '.\HealthReport.html'
$HealthReport