# Install required modules if not already installed
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -AllowClobber -Force
}
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Force
}

# Connect to Azure AD
Disconnect-AzAccount
Connect-AzAccount

# Path to the Excel file
# $excelFilePath = "C:\path\to\your\users.xlsx"


# Import users from the Excel file
# $users = Import-Excel -Path $excelFilePath -WorksheetName "Sheet1" | Select-Object -ExpandProperty UserPrincipalName
# # Define the list of users to add (either by ObjectId or UserPrincipalName)
$users = @("", "", "", "", "", "")



# Define the string parts of the security group name to search for
$groupNamePart1 = "ssss*"
$groupNamePart2 = "*sssss"

# Enable simulation mode (set to $true for simulation, $false for actual execution)
$simulationMode = $false

# Retrieve all security groups containing both specified string parts in their DisplayName
$groups = Get-AzADGroup | Where-Object { $_.DisplayName -like "$groupNamePart1" -and $_.DisplayName -like "$groupNamePart2" }
$groups
($groups).Length

# Initialize counters for the total number of users created or would be created
$totalUsersCreated = 0
$totalUsersSimulated = 0

# Loop through the matched groups and add users to each group if they are not already members
foreach ($group in $groups) {
    foreach ($user in $users) {
        try {
            # Retrieve user by UserPrincipalName
            $userObject = Get-AzADUser -UserPrincipalName $user
            
            # Check if the user is already a member of the group
            $isMember = Get-AzADGroupMember -GroupObjectId $group.Id | Where-Object { $_.ObjectId -eq $userObject.Id }
            
            if (-not $isMember) {
                if ($simulationMode) {
                    Write-Host "SIMULATION: Would add user $($userObject.UserPrincipalName) to group $($group.DisplayName)"
                    # Increment the simulation counter
                    $totalUsersSimulated++
                } else {
                    # Add user to the group if they are not already a member
                    Add-AzADGroupMember -TargetGroupObjectId $group.Id -MemberObjectId $userObject.Id
                    Write-Host "Added user $($userObject.UserPrincipalName) to group $($group.DisplayName)"
                    # Increment the counter
                    $totalUsersCreated++
                }
            } else {
                Write-Host "User $($userObject.UserPrincipalName) is already a member of group $($group.DisplayName)"
            }
        } catch {
            Write-Host "Failed to add user $user to group $($group.DisplayName): $_"
        }
    }
}

# Display the total number of users created or would be created
if ($simulationMode) {
    Write-Host "SIMULATION MODE: Total users that would be created: $totalUsersSimulated"
} else {
    Write-Host "ACTUAL EXECUTION: Total users created: $totalUsersCreated"
}

# To execute the script for real, set $simulationMode to $false


#test: should add 23SGs*6users = 138