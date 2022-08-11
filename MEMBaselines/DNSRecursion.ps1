#query
$querydns = Get-DnsServerRecursion
If($querydns.Enable -eq $true){
Return $true
}else{
Return $false
}


#remediate
#Set-DnsServerRecursionScope -Name . -EnableRecursion $False
#Add-DnsServerRecursionScope -Name "InternalAdatumClients" -EnableRecursion $True

#Add-DnsServerQueryResolutionPolicy -Name "RecursionControlPolicy" -Action ALLOW
#-ApplyOnRecursion -RecursionScope "InternalAdatumClients" -ServerInterfaceIP
#"EQ,10.24.60.254"
