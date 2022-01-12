Write-Output "Login into the Azure Account"
az login
#Variables
$ipListFileInput = "C:\" + $subscriptionName + "_ipList.txt"
$ipListFileOutput = "C:\" + $subscriptionName + "_ipListoutput.txt"
Write-Output "List subscriptions"

#Filtering the output
$allsubscriptions = az account list --query '[].[id, name]' -o tsv

#Cycling for each subscription
foreach ($subscription in $allsubscriptions) {
   $arrValues = $subscription.Split("`t")
   $subscriptionId = $arrValues[0]
   $subscriptionName = $arrValues[1]

   Write-Output "Get IP for subription id " + $subscriptionId.ToString()
   $allPublicIP = az network public-ip list --subscription $subscriptionId --query '[].[ipAddress]' -o tsv

   #Create the empty array for ips
   $OutputArray = @()

   #Cycling for each ip
   foreach ($ip in $allPublicIP){
      $OutputArray += $ip
   }

   Write-Output "Write to file"
   [System.IO.File]::WriteAllLines($ipListFileInput, $OutputArray)
   Write-Output "Execute the scan"
   nmap -v -p 1-65535 -sV -O -sS -T5 -iL $ipListFileInput | Out-File $ipListFileOutput
}