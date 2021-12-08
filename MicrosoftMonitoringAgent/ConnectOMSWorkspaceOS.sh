sudo su omsagent
if [ "$result" = "$WSID" ]; then 
echo "Strings are equal" 
else 
echo "fekeefff" 
fi

WS_ASGN="([0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12})"
var=$(grep WORKSPACE_ID /etc/opt/microsoft/omsagent/conf/omsadmin.conf)
result=$(echo $var | grep -E -o $WS_ASGN)
echo $?

DIR="/opt/microsoft/omsconfig/"
WSID="69860496-a11d-4692-8c79-fa89789c406e"
SK="<enter SK>"
if [ -d "$DIR" ]; then
  ### Take action if $DIR exists ### if RedHat change line 7 to Python3 ###
  echo "DIR Found, checking the install"
  sudo su omsagent -c WSID="69860496-a11d-4692-8c79-fa89789c406e"
  WS_ASGN="([0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12})"
  var=$(grep WORKSPACE_ID /etc/opt/microsoft/omsagent/conf/omsadmin.conf)
  if [ "$result" = "$WSID" ]; then 
  echo "Correct Workspace is added already"
  sudo /opt/microsoft/omsagent/bin/service_control restart 
  else 
  echo "Adding Correct Workspace"
  sudo /opt/microsoft/omsagent/bin/omsadmin.sh -w $WSID -s $SK
  sudo /opt/microsoft/omsagent/bin/service_control restart
  fi 
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