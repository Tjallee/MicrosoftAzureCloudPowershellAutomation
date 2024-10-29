# Install Az module if not already installed
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -AllowClobber -Force
}

# Connect to Azure AD
Disconnect-AzAccount
Connect-AzAccount

# Set to $true for simulation mode, $false for actual execution
$SimulationMode = $false

# Define the string parts of the security group name to search for
$groupNamePart1 = "ssss*"
$groupNamePart2 = "*_VIEWER"

# Get all groups that have both strings in their DisplayName
$viewerGroups = Get-AzADGroup | Where-Object { $_.DisplayName -like "$groupNamePart1" -and $_.DisplayName -like "$groupNamePart2" }
$viewerGroups
($viewerGroups).Length #23, good to go.

# Loop through the 'VIEWER' groups and create corresponding 'CONTRIBUTOR' groups if they do not exist
foreach ($group in $viewerGroups) {
    $newName = $group.DisplayName -replace "VIEWER", "CONTRIBUTOR"
    
    # Check if the 'CONTRIBUTOR' group already exists
    $existingGroup = Get-AzADGroup | Where-Object { $_.DisplayName -eq $newName }
    
    if (-not $existingGroup) {
        if ($SimulationMode) {
            # Simulating the creation of the new security group
            Write-Host "Simulating creation of Group: $newName"
        } else {
            # Creating the new security group
            New-AzADGroup -DisplayName $newName -MailNickname $newName
            Write-Host "Created Group: $newName"
        }
    } else {
        Write-Host "Group $newName already exists. Skipping creation."
    }
}


# Currently there are 46 SG's manually made in Entra for XX. This should become 69 (46/2=23 so another 23 on top of the 46 we currently have)
# TEST:

Get-AzADGroup | Where-Object { $_.DisplayName -like "*CONTRIBUTOR" }


