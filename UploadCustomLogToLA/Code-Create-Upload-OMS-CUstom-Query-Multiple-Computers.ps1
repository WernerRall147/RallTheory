# Replace with your Workspace ID
$CustomerId = "insert"  

# Replace with your Primary Key
$SharedKey = "insert"

# Specify the name of the record type that you'll be creating
$LogName = "TestUpload4"  # this will be searchable as MyCustomLogs_CL

# Specify a field with the created time for the records
$TimeStampField = "DateValue"

# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
 
    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)
 
    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}
 
 
# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
 
    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }
 
    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}
 
#collect data and store in a scustom object 
#just a sample, get computer properties and upload them to oms 

$logUpload=@()
$Servers =  @("za-weral2311" , "PC1", "PC2")
$datestring = (Get-Date).ToString("s").Replace(":","-")
$errorServers = New-Item $env:TEMP\ServerUploadErrors_$datestring.txt
$date = (Get-Date).ToString()


Foreach($Server in $Servers){

If(!(Test-Connection -ComputerName $server -Count 1 -Quiet)){
Add-Content $errorServers "$Server"
  Continue
  }

Try{
$ComputerInf = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Server
$ComputerInf2 = Get-WmiObject -class Win32_BIOS -ComputerName $Server
}
Catch
{
Write-Warning "$server Can't check for accounts, likely RPC server unavailable"
  Continue
}
Finally
{
   $logUpload = new-object pscustomobject -Property @{            
                ComputerName = $ComputerInf.PSComputerName
                OS = $ComputerInf.Caption
                Model = $Computerinf2.Manufacturer
                Date = $date}
# Submit the data to the API endpoint
#$jsonlogs= ConvertTo-Json -InputObject $logUpload

# Create two records with the same set of properties to create
$json = @"
[{  "StringValue": "$ComputerInf.PSComputerName",
    "NumberValue": 42,
    "BooleanValue": true,
    "DateValue": "2019-09-12T20:00:00.625Z",
},
{   "StringValue": "MyString2",
    "NumberValue": 43,
    "BooleanValue": false,
    "DateValue": "2019-09-12T20:00:00.625Z",
    "GUIDValue": "8809ED01-A74C-4874-8ABF-D2678E3AE23D"
}]
"@

Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logname
}
}
 
 #alternative way to post
 #Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $SharedKey -body $jsonlogs -logType $Logname -TimeStampField $TimeStampField


