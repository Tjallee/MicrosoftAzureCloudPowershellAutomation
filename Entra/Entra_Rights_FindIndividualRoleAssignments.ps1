# # Connect to Azure AD
Disconnect-AzAccount
Connect-AzAccount

# # # Log-in to Azure CLI
az logout
az login

# Import the ImportExcel module
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
}

# Set the subscription context
#$subscriptionId = "" #id of subscription
#$subscriptionId = "" #name of subscription (choose which your prefer to use as sheetname when storing)
$subscriptionId = "" 
az account set --subscription $subscriptionId
az account show

# Get all role assignments for the subscription
Write-Output "Fetching all role assignments..."
$roleAssignmentsRaw = az role assignment list --all --query "[].{principalType:principalType, principalName:principalName, roleName:roleDefinitionName, scope:scope}" -o json

# Check if the output is valid JSON
if ($roleAssignmentsRaw -match '^\s*\[') {
    $roleAssignments = $roleAssignmentsRaw | ConvertFrom-Json
} else {
    Write-Error "Failed to parse role assignments JSON. Output: $roleAssignmentsRaw"
    exit
}

# Filter out role assignments that are not for users
$userRoleAssignments = $roleAssignments | Where-Object { $_.principalType -eq 'User' }

# Initialize a hash table to store user roles by user
$userRoles = @{}
$failedUsers = @()

# Group role assignments by user
foreach ($assignment in $userRoleAssignments) {
    $userName = $assignment.principalName
    $roleName = $assignment.roleName
    $resourceScope = $assignment.scope

    # Initialize the user entry if not already present
    if (-not $userRoles.ContainsKey($userName)) {
        $userRoles[$userName] = @()
    }

    # Add role information to the user's list
    $userRoles[$userName] += [PSCustomObject]@{
        Role = $roleName
        Resource = $resourceScope
    }
}

# Display grouped role assignments
Write-Output "Grouped role assignments by user:"
foreach ($user in $userRoles.Keys) {
    Write-Output "
    "
    Write-Output "User: $user"
    foreach ($role in $userRoles[$user]) {
        Write-Output "  Role: $($role.Role), Resource: $($role.Resource)"
        Write-Output ""
    }
    Write-Output "
    "
}

# Prepare results for Excel export
$exportData = @()

foreach ($user in $userRoles.Keys) {
    if ($userRoles[$user].Count -eq 0) {
        # Report an error if a user has no role assignments
        Write-Error "No role assignments found for user: $user"
        $failedUsers += $user
    } else {
        # Collect data for Excel export
        foreach ($roleAssignment in $userRoles[$user]) {
            $exportData += [PSCustomObject]@{
                User = $user
                Role = $roleAssignment.Role
                Resource = $roleAssignment.Resource
            }
        }
    }
}

# Export results to Excel
$excelFilePath = "C:\....\UserRoleAssignments_Review_$subscriptionId.xlsx" #adjust folder in which you want to store
Write-Output "Exporting results to Excel..."
$exportData | Export-Excel -Path $excelFilePath -WorksheetName "RoleAssignmentsPerUserPerResource" -AutoSize -AutoFilter

Write-Output "Exported role assignments to $excelFilePath"

# Report users with failed role assignment retrieval
if ($failedUsers.Count -gt 0) {
    Write-Output "Errors encountered for the following users:"
    foreach ($failedUser in $failedUsers) {
        Write-Output $failedUser
    }
} else {
    Write-Output "No errors encountered."
}
