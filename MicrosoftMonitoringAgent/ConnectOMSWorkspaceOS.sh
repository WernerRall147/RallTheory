sudo /opt/microsoft/omsagent/bin/omsadmin.sh -w <workspace> -s <keys> -v
sudo /opt/microsoft/omsagent/bin/service_control restart

##Use this for purging
## wget https://raw.githubusercontent.com/microsoft/OMS-Agent-for-Linux/master/tools/purge_omsagent.sh
## sudo sh purge_omsagent.sh

###Use this for install inside the OS
## 
## 

###Use this for adding the extension
## az vm extension set \
##  --resource-group myResourceGroup \
##  --vm-name myVM \
##  --name OmsAgentForLinux \
##  --publisher Microsoft.EnterpriseCloud.Monitoring \
##  --protected-settings '{"workspaceKey":"myWorkspaceKey"}' \
##  --settings '{"workspaceId":"myWorkspaceId"}'