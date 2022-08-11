$state = Get-WebsiteState -Name "Default Web Site"

If($state.Value -eq "Started")
{
Return $true
}else
{
Return $false
}