#Report
$Sites = Get-Website | select Name

Foreach($w in $sites.Name){
$verbs = Get-IISConfigSection -CommitPath "$w" -SectionPath 'system.webServer/security/requestFiltering' | Get-IISConfigCollection -CollectionName 'verbs'
$rawatts = Get-IISConfigCollectionElement -ConfigCollection $verbs | select rawattributes | select -ExpandProperty *
$cleaned = $rawatts | Out-String

If($cleaned -match 'GET' )
{
Return $true
}else{
Return $false
}
}



#Remediate
$Sites = Get-Website | select Name

Foreach($w in $sites.Name){
$verbs = Get-IISConfigSection -CommitPath "$w" -SectionPath 'system.webServer/security/requestFiltering' | Get-IISConfigCollection -CollectionName 'verbs'
Start-IISCommitDelay
Set-IISConfigAttributeValue -ConfigElement $verbs -AttributeName 'applyToWebDAV' -AttributeValue $false
New-IISConfigCollectionElement -ConfigCollection $verbs -ConfigAttribute @{ 'verb'='OPTIONS';'allowed'=$false }
Stop-IISCommitDelay
}


