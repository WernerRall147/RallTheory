# Variables
resourceGroup="#TODO"
userObjectId="#TODO"
managedIdentityObjectId1="#TODO"
managedIdentityObjectId2="#TODO"
subscriptionId="#TODO"

# Assign Cognitive Services OpenAI Contributor
az role assignment create --assignee $userObjectId --role "Cognitive Services OpenAI Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId1 --role "Cognitive Services OpenAI Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId2 --role "Cognitive Services OpenAI Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup

# Assign Cognitive Services Contributor
az role assignment create --assignee $userObjectId --role "Cognitive Services Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId1 --role "Cognitive Services Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId2 --role "Cognitive Services Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup

# Assign Search Index Data Reader
az role assignment create --assignee $userObjectId --role "Search Index Data Reader" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId1 --role "Search Index Data Reader" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId2 --role "Search Index Data Reader" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup

# Assign Storage Blob Data Contributor
az role assignment create --assignee $userObjectId --role "Storage Blob Data Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId1 --role "Storage Blob Data Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId2 --role "Storage Blob Data Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup

# Assign Search Service Contributor
az role assignment create --assignee $userObjectId --role "Search Service Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId1 --role "Search Service Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup
az role assignment create --assignee $managedIdentityObjectId2 --role "Search Service Contributor" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup