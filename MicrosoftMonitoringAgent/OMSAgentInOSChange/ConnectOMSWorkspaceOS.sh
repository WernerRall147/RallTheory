## Use the below when running interactive
#read -p 'Log Analytics Workspace ID: ' WSID
#read -p 'Log Analytics Workspace Shared Key: ' SK

#Update the below details with your Log Analytics Workspace
WSID="<Ws key>"
SK="<sk key>"
#Directory to check if OMS agent has ever been installed
DIR="/opt/microsoft/omsconfig/"
if [ -d "$DIR" ]; then
  ### Take action if $DIR exists
  echo "Agent Directory Found, checking the install"
  #regex to look for Workspace ID 
  WS_ASGN="([0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12})"
  #CD to OMSAgent Dir
  cd /etc/opt/microsoft/omsagent
  #Find Workspace ID in dir
  var=dir
  #Extract WorkspaceID
  result=$($var | grep -E -o $WS_ASGN)
  #If Workspace is the same as required Workspace then only restart the service
  if [ "$result" = "$WSID" ]; then 
  echo "Correct Workspace is added already"
  sudo /opt/microsoft/omsagent/bin/service_control restart
  #If the workspace is not the same add the correct workspace
  else 
  echo "Adding Correct Workspace"
  sudo /opt/microsoft/omsagent/bin/omsadmin.sh -w $WSID -s $SK
  sudo /opt/microsoft/omsagent/bin/service_control restart
  fi 
#If directory is not found then install the OMS Agent for Linux
else
  echo "${DIR} not found. Starting the install."
  wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh -w $WSID -s $SK
  sudo /opt/microsoft/omsagent/bin/service_control restart
  exit 0
fi


##sudo su omsagent -c '/opt/microsoft/omsagent/bin/omsadmin.sh -l'
##wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh -w <YOUR WORKSPACE ID> -s <YOUR WORKSPACE PRIMARY KEY>
##sudo /opt/microsoft/omsagent/bin/omsadmin.sh -w <workspace> -s <keys> -v
##sudo /opt/microsoft/omsagent/bin/service_control restart

##Use this for purging
## wget https://raw.githubusercontent.com/microsoft/OMS-Agent-for-Linux/master/tools/purge_omsagent.sh
## sudo sh purge_omsagent.sh

###Use this for install inside the OS
## wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh -w <YOUR WORKSPACE ID> -s <YOUR WORKSPACE PRIMARY KEY>

###Use this for adding the extension
## az vm extension set \
##  --resource-group myResourceGroup \
##  --vm-name myVM \
##  --name OmsAgentForLinux \
##  --publisher Microsoft.EnterpriseCloud.Monitoring \
##  --protected-settings '{"workspaceKey":"myWorkspaceKey"}' \
##  --settings '{"workspaceId":"myWorkspaceId"}'