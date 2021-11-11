$workspaceId = "<WS ID>"
$workspaceKey = "<WS KEy>"
$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
$mma.AddCloudWorkspace($workspaceId, $workspaceKey)

param($ProxyDomainName="https://proxy.contoso.com:30443")

$proxyMethod = $mma | Get-Member -Name 'SetProxyUrl'
if (!$proxyMethod)
{
    Write-Output 'Health Service proxy API not present, will not update settings.'
    return
}

Write-Output "Clearing proxy settings."
$mma.SetProxyUrl('')

Write-Output "Setting proxy to $ProxyDomainName"
$mma.SetProxyUrl($ProxyDomainName)
$mma.ReloadConfiguration()
