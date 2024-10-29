# Install Az module if not already installed
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -AllowClobber -Force
}

# Function to remove licenses from deactivated users
function Remove-LicensesFromDeactivatedUsers {
    param (
        [switch]$SimulationMode
    )



    # Connect to Azure AD
    Connect-AzAccount

    # Get all deactivated users
    $deactivatedUsers = Get-AzADUser -Filter "AccountEnabled eq false" 
    # $deactivatedUsers
    # ($deactivatedUsers).Length

    foreach ($user in $deactivatedUsers) {
        Write-Host "Processing $($user.UserPrincipalName)"

        # Get assigned licenses for the user
        $licenses = Get-AzADUserLicenseDetail -ObjectId $user.ObjectId

        if ($licenses.Count -gt 0) {
            foreach ($license in $licenses) {
                $licenseSku = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
                $licenseSku.SkuId = $license.SkuId
                $licenseSku.DisabledPlans = $license.DisabledPlans

                if ($SimulationMode) {
                    Write-Host "[SIMULATION] Would remove license $($license.SkuPartNumber) from user $($user.UserPrincipalName)"
                } else {
                    Write-Host "Removing license $($license.SkuPartNumber) from user $($user.UserPrincipalName)"
                    # Remove the license assignment
                    Set-AzADUserLicense -ObjectId $user.ObjectId -AssignedLicenses $licenseSku
                }
            }
        } else {
            Write-Host "No licenses to remove for $($user.UserPrincipalName)"
        }
    }

    Write-Host "License removal process completed."
}

# Function to display usage
function Show-Usage {
    Write-Host "Usage: .\RemoveDeactivatedUserLicenses.ps1 [-Simulation]"
    Write-Host "  -Simulation    Run the script in simulation mode to see which licenses would be removed."
}

# Main script logic
param (
    [switch]$Simulation
)

# Display usage if help is requested
if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Help')) {
    Show-Usage
} else {
    Remove-LicensesFromDeactivatedUsers -SimulationMode:$Simulation
}

