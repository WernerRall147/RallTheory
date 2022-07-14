# Enable support for TLS 1.2 in your environment for Azure AD TLS 1.1 and 1.0 deprecation
# https://docs.microsoft.com/en-us/troubleshoot/azure/active-directory/enable-support-tls-environment?tabs=azure-monitor

# To improve the security posture of your tenant, and to remain in compliance with industry standards, Microsoft Azure Active Directory (Azure AD) will soon stop supporting the following Transport Layer Security (TLS) protocols and ciphers:
# TLS 1.1
# TLS 1.0
# 3DES cipher suite (TLS_RSA_WITH_3DES_EDE_CBC_SHA)

# How this change might affect your organization
# Do your applications communicate with or authenticate against Azure Active Directory? Then those applications might not work as expected if they can't use TLS 1.2 to communicate. This situation includes:
# Azure AD Connect
# Azure AD PowerShell
# Azure AD Application Proxy connectors
# PTA agents
# Legacy browsers
# Applications that are integrated with Azure AD

#This PowerShell will attempt to look up all above mentioned Technologies
#Modules Required:
# AzureAD
# Install-Module -Name AADInternals

function ConnectAzure(){
    Connect-AzAccount
} 

function AzureADConnectLookup(){

}



function AzureADPowerShellConnections(){}

function AzureADAppProxyConnectors(){}

function PTAAgentslookup(){}

function LegacyBrowsersLookup(){}

function ApplicationsIntegratedWithAzureAD(){}