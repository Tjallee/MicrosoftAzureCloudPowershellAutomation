# #TEST
# # Specify the path to the Excel file
# $excelFilePath = "C:\"

# # Specify the worksheet name
# $sheetName = "Test1DEV"

# # Import the Excel file
# $data = Import-Excel -Path $excelFilePath -WorksheetName $sheetName
# foreach ($row in $data) {
#     $userEmail = $row.EmailAddress
#     $groupName = $row.SecurityGroup
#     $roleName = $row.Role
#     $resourceScope = $row.Resource

#     Write-Host "Email: $userEmail"
#     Write-Host "Group: $groupName"
#     Write-Host "Role: $roleName"
#     Write-Host "Resource: $resourceScope"
# }





# Connect to Azure AD
Disconnect-AzAccount
Connect-AzAccount
# Update-PSResource Az -WhatIf #Simulate updating your Az modules.
# Update-PSResource Az #Update your Az modules.

# # Log-in to Azure CLI
az logout
az login
# az upgrade

# Import necessary modules
Import-Module AzureAD
Import-Module ImportExcel
Import-Module Az.Resources
Import-Module Microsoft.Graph
# Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
Connect-MgGraph -Scopes "Group.ReadWrite.All","RoleManagement.ReadWrite.Directory"


# Specify the group owners' email addresses (UserPrincipalNames)
$groupOwner1Email = ""
$groupOwner2Email = ""

# Retrieve the group owners' Azure AD user objects
$groupOwner1 = Get-AzADUser -Filter "UserPrincipalName eq '$groupOwner1Email'"
$groupOwner2 = Get-AzADUser -Filter "UserPrincipalName eq '$groupOwner2Email'"

# if (-not $groupOwner1) {
#     Write-Host "Group owner 1 not found: $groupOwner1Email" -ForegroundColor Red
#     exit
# }

# if (-not $groupOwner2) {
#     Write-Host "Group owner 2 not found: $groupOwner2Email" -ForegroundColor Red
#     exit
# }

# Specify the path to the Excel file
$excelFilePath = "C:\"

# Specify the worksheet name
$sheetName = "PRD"
$subscriptionName = az account show --query name --output tsv #for subscription and sheet check.

# Import the Excel file
$data = Import-Excel -Path $excelFilePath -WorksheetName $sheetName

#Subscription and Excel Sheet Name check before executing
if ($subscriptionName.Contains($sheetName)) {
    Write-Host "Excel Sheet Name $sheetName is contained in Subscription Name $subscriptionName, proceeding with the execution."
    # Loop through each row in the Excel file
    foreach ($row in $data) {
        $userEmail = $row.EmailAddress
        $groupName = $row.SecurityGroup
        $roleName = $row.Role
        $resourceScope = $row.Resource


        # Check if the Security Group exists
        $group = Get-AzADGroup |Where-Object {$_.DisplayName -eq $groupName}

        # If the group does not exist, create it
        if (-not $group) {
            Write-Host "Creating security group: $groupName"
            $group = New-AzADGroup -DisplayName $groupName -MailNickname $groupName -MailEnabled:$false -SecurityEnabled:$true -IsAssignableToRole:$true
            #Get-Help New-AzADGroup -Full

            # Add group owners
            Write-Host "Adding group owners to $groupName"
            New-AzADGroupOwner -GroupId $group.Id -OwnerId $groupOwner1.Id
            New-AzADGroupOwner -GroupId $group.Id -OwnerId $groupOwner2.Id
        } else {
            Write-Host "Security group $groupName already exists."
            $group = Get-AzADGroup -DisplayName $groupName 
        }

        # Get the user object
        $user = Get-AzADUser -Filter "UserPrincipalName eq '$userEmail'"

        # If user exists, add to the group
        if ($user) {
            # Check if the user is already a member of the group
            $isMember = Get-AzADGroupMember -GroupObjectId $group.Id | Where-Object { $_.MemberObjectId -eq $user.Id }
            
            if (-not $isMember) {
                Write-Host "Adding $userEmail to $groupName"
                Add-AzADGroupMember -TargetGroupObjectId $group.Id -MemberObjectId $user.Id
            } else {
                Write-Host "$userEmail is already a member of $groupName"
            }
        } else {
            Write-Host "User $userEmail not found in Azure AD."
        }

        # Assign Azure Role to the Security Group if Role and Resource are specified
        if ($roleName -and $resourceScope) {
            # Check if the role assignment already exists
            $roleAssignment = Get-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName $roleName -Scope $resourceScope

            if (-not $roleAssignment) {
                Write-Host "Assigning role $roleName to group $groupName at scope $resourceScope"
                New-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName $roleName -Scope $resourceScope
            } else {
                Write-Host "Group $groupName already has the $roleName role assigned at scope $resourceScope."
            }
        }
    }

}
else {
    Write-Host "The sheetname and subscription do not match. Check if you specified the correct sheet or selected the correct subscription before proceeding."
}
