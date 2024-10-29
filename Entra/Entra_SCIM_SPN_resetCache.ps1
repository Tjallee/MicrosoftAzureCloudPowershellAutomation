#In case ppm app and SCIM fall out of sync. You don't need to mess around in SCIM anymore. 
#In case an account was accidentally reactivated in the app, you can execute this script with the SPN objectId and SCIM jobId to reset the cached adjustments made by scim.
#SCIM will re-evaluate the state in the target app and deactivate the account again.

# Connect to Azure AD
Disconnect-AzAccount
Connect-AzAccount
# Update-PSResource Az -WhatIf #Simulate updating your Az modules.
# Update-PSResource Az #Update your Az modules.

# # Log-in to Azure CLI
az logout
az login
# az upgrade



Import-Module Microsoft.Graph.Applications
Connect-MgGraph

#The ObjectId of the Service Principal of your SCIM app
$servicePrincipalId = ""

#The JobId found in the provisioning tab in the Service Principal of your SCIM app. Go to
$synchronizationJobId = ""



$params = @{
	criteria = @{
		resetScope = "Full"
	}
}

Restart-MgServicePrincipalSynchronizationJob -ServicePrincipalId $servicePrincipalId -SynchronizationJobId $synchronizationJobId -BodyParameter $params

