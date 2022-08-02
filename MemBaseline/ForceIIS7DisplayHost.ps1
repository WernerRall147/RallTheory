#Report
$hostNme = [System.Net.Dns]::GetHostByName($env:computerName)
$Sites = Get-Website | select Name

Foreach($w in $sites.Name){
Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location "$w" -filter "system.webServer/serverRuntime" -name "alternateHostName" 
}


#Remediate 
$hostNme = [System.Net.Dns]::GetHostByName($env:computerName)
$Sites = Get-Website | select Name
Foreach($w in $sites.Name){
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location "$w" -filter "system.webServer/serverRuntime" -name "alternateHostName" -value "$hostnme.hostname"
}