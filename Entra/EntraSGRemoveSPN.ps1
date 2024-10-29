# Ensure AzureAD module is installed and imported
if (-not (Get-Module -ListAvailable -Name AzureAD)) {
    Install-Module -Name AzureAD -Force
}
Import-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Get all service principals with the specified naming patterns
$servicePrincipals = Get-AzADServicePrincipal | Where-Object { $_.DisplayName -like "ssss*" -and $_.DisplayName -like "*_SPN" }
Write-Output $servicePrincipals

# Get all security groups with the specified naming patterns
$securityGroups = Get-AzADGroup | Where-Object { $_.DisplayName -like "ssss*" -and $_.DisplayName -like "*_VIEWER" }
Write-Output $securityGroups

# Iterate through each security group
foreach ($group in $securityGroups) {
    Write-Output "Processing group: $($group.DisplayName) ($($group.Id))"
    
    # Iterate through each service principal
    foreach ($sp in $servicePrincipals) {
        Write-Output "Checking if service principal: $($sp.DisplayName) ($($sp.Id)) is a member of group: $($group.DisplayName)"
        
        # Check if the service principal is a member of the group
        $isMember = Get-AzADGroupMember -GroupObjectId $group.Id | Where-Object { $_.Id -eq $sp.Id }

        if ($isMember) {
            Write-Output "Removing service principal: $($sp.DisplayName) ($($sp.Id)) from group: $($group.DisplayName)"
            
            # Remove the service principal from the group
            Remove-AzADGroupMember -GroupObjectId $group.Id -MemberObjectId $sp.Id
        }
    }
}

Write-Output "Script execution completed."



# Part II - add SPN to the right SG with ADMIN in it

# Import the AzureAD module
Import-Module AzureAD
                                                                                                     
# Connect to Azure AD
Connect-AzureAD

# Variables for the service principal name and security group name
# Get-AzADServicePrincipal $.DisplayName | Where-Object { $_.DisplayName -like "ss*" -and $_.DisplayName -like "*_SPN" }
# $servicePrincipalName = "ss_SPN"
# $securityGroupName = "sg_ADMIN"

$servicePrincipalName = "ss_SPN"
$securityGroupName = "sg_ADMIN"

# Get the service principal
$servicePrincipal = Get-AzADServicePrincipal -Filter "displayName eq '$servicePrincipalName'"

if ($null -eq $servicePrincipal) {
    Write-Host "Service principal '$servicePrincipalName' not found"
    exit
}

# Get the security group
$securityGroup = Get-AzADGroup -Filter "displayName eq '$securityGroupName'"

if ($null -eq $securityGroup) {
    Write-Host "Security group '$securityGroupName' not found"
    exit
}

# Add the service principal to the security group
Add-AzADGroupMember -TargetGroupObjectId $securityGroup.Id -MemberObjectId $servicePrincipal.Id

Write-Host "Service principal '$servicePrincipalName' has been added to the security group '$securityGroupName'"
