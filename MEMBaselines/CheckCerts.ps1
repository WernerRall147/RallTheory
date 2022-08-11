$FinalResult = @()
$Threshold = 90
$Allcertificates = Get-ChildItem -Path Cert:\LocalMachine\AuthRoot

foreach ($Cert in $Allcertificates) {
    If ($Cert.NotAfter -lt (Get-Date).AddDays($Threshold)) {
    $FinalResult += New-Object psobject @{Value = $Cert.SubjectName}
    }
}

 if ($FinalResult) {
     Return $true
 }
 else {
     Return $false
 }