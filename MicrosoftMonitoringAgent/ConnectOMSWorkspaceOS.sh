sudo /opt/microsoft/omsagent/bin/omsadmin.sh -w <workspace> -s <keys> -v
sudo /opt/microsoft/omsagent/bin/service_control restart

##Use this for purging
## wget https://raw.githubusercontent.com/microsoft/OMS-Agent-for-Linux/master/tools/purge_omsagent.sh
## sudo sh purge_omsagent.sh