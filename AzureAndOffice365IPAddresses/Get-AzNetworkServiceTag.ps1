$serviceTags = Get-AzNetworkServiceTag -Location eastus
$servicetags = $serviceTags.Values #| Where-Object { $_.Name -eq "Storage" }
$servicetags.Properties.AddressPrefixes
$IPGroup = $servicetags.Properties.AddressPrefixes
$IPGroup | out-file .\IPGroup22.csv -NoClobber

#$JSONUrl = "https://www.microsoft.com/en-in/download/details.aspx?id=56519/ServiceTags_Public_20240513.json"
#$csvContent = Invoke-WebRequest -Uri $csvUrl 
#$skuLookup = $csvContent | ConvertFrom-Csv
#$jsonfile = Get-Content .\ServiceTags_Public_20240513.json | convertfrom-json | select *