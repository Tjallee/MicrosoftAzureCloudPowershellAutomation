# Install Az module if not already installed
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -AllowClobber -Force
}

# Connect to Azure AD
Connect-AzAccount

# Retrieve all security groups containing 'LADMIN' in their DisplayName
$groups = Get-AzADGroup | Where-Object { $_.DisplayName -like "*LADMIN*" }

# Loop through the groups and update their DisplayName
foreach ($group in $groups) {
    $newName = $group.DisplayName -replace "LADMIN", "VIEWER"
    Update-AzADGroup -ObjectId $group.Id -DisplayName $newName
    Write-Host "Updated Group: $($group.DisplayName) to $newName"
}

# TEST:
$groups = Get-AzADGroup | Where-Object { $_.DisplayName -like "*VIEWER*" }