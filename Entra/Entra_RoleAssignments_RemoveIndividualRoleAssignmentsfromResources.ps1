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


# Specify the path to the Excel file to import
$excelFilePath = "C:\"

# Specify the worksheet name abbreviation based on subscription name
$sheetName = "PRD" #execute only after SGs are correct and approved.
$subscriptionName = az account show --query name --output tsv #for subscription and sheet check.

# Import the Excel file
$data = Import-Excel -Path $excelFilePath -WorksheetName $sheetName

#Subscription and Excel Sheet Name check before executing
if ($subscriptionName.Contains($sheetName)) {
    Write-Host "Excel Sheet Name $sheetName is contained in Subscription Name $subscriptionName, proceeding with the execution."
# Loop through each row in the Excel file
    foreach ($row in $data) {
        $userEmail = $row.EmailAddress
        $roleName = $row.Role
        $resourceScope = $row.Resource

        # Get the user object
        $user = Get-AzADUser -Filter "UserPrincipalName eq '$userEmail'"

        # Remove Direct Individual Azure Role Permission from the resource if Role and Resource are specified
        if ($roleName -and $resourceScope) {
            # Check if the role assignment already exists
            $roleAssignment = Get-AzRoleAssignment -ObjectId $user.Id -RoleDefinitionName $roleName -Scope $resourceScope

            if ($roleAssignment) {
                Write-Host "Removing direct Azure Role Permission $roleName of user $user from resource $resourceScope"
                Remove-AzRoleAssignment -ObjectId $user.Id -RoleDefinitionName $roleName -Scope $resourceScope
            } else {
                Write-Host "The direct Azure Role Permission $roleName was already removed from resource $resourceScope for user $user."
            }
        }
    }
}
else {
    Write-Host "The sheetname and subscription do not match. Check if you specified the correct sheet or selected the correct subscription before proceeding."
}