
function parseGroupAndName{
    param (
       [string]$resourceID
   )
   $array = $resourceID.Split('/') 
   $indexV = 0..($array.Length -1) | where {$array[$_] -eq 'virtualmachines'}
   $result = $array.get($indexV+1)
   return $result
}

$g = Get-AzDataCollectionRule | Get-AzDataCollectionRuleAssociation | select id
foreach($resourceID in $g){
    parseGroupAndName -resourceID $resourceID
}
