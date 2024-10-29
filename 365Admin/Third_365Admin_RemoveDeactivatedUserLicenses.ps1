# Install the necessary module if not already installed
if (-not (Get-Module -ListAvailable -Name MSOnline)) {
    Install-Module MSOnline -Force -Confirm:$false
}

# Import the MSOnline module
Import-Module MSOnline

# Connect to Microsoft 365 tenant
$UserCredential = Get-Credential
Connect-MsolService -Credential $UserCredential

# Get all disabled users who have licenses assigned
$DisabledUsers = Get-MsolUser -All | Where-Object { $_.IsLicensed -eq $true -and $_.UserPrincipalName -ne $null -and $_.UserState -eq 'Disabled' }

# Remove licenses from disabled users
$DisabledUsers | ForEach-Object { 
    $_.Licenses | ForEach-Object { 
        Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -RemoveLicenses $_.AccountSkuId 
    }
}

# Verify the changes (optional)
$RemainingLicensedDisabledUsers = Get-MsolUser -All | Where-Object { $_.IsLicensed -eq $true -and $_.UserPrincipalName -ne $null -and $_.UserState -eq 'Disabled' }

# Display remaining licensed disabled users (should be empty if successful)
$RemainingLicensedDisabledUsers
