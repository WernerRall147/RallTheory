#This section adds a new Workspace
$workspaceId = "<WS ID>"
$workspaceKey = "<WS KEy>"
$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
$mma.AddCloudWorkspace($workspaceId, $workspaceKey)

#This section is where the Proxy can be configured
param($ProxyDomainName="https://proxy.contoso.com:30443")

$proxyMethod = $mma | Get-Member -Name 'SetProxyUrl'
if (!$proxyMethod)
{
    Write-Output 'Health Service proxy API not present, will not update settings.'
    return
}

#Clears Proxy settings in MMA
Write-Output "Clearing proxy settings."
$mma.SetProxyUrl('')

#Adds new proxy settings
Write-Output "Setting proxy to $ProxyDomainName"
$mma.SetProxyUrl($ProxyDomainName)
$mma.ReloadConfiguration()
