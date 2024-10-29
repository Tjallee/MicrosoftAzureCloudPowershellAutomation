$entraSGs = Get-AzADGroup | Where-Object {$_.DisplayName -eq ""}

# Store all active users
$activeUsers = Get-AzADUser -Filter "accountEnabled eq true" | Sort-Object -Property "DisplayName"

#Initialize hash table to store results
$activeUsersPerSG = @{}

#Create a loop that lists all  active users per SG alphabetically and store them. Next, export them in an excelfile.
foreach ($group in $entraSGs) {
    $securityGroup = $group.DisplayName
    $sGMembers = Get-AzADGroupMember -GroupObjectId $group.Id | Sort-Object -Property "DisplayName"
    foreach ($member in $sGMembers) {
        if ($activeUsers.Id -contains $member.Id -and -not $activeUsersPerSG.ContainsKey($member.Id)) {
            # Check if the security group is already a key in the hash table
            if (-not $activeUsersPerSG.ContainsKey($securityGroup)) {
                $activeUsersPerSG[$securityGroup] = @()
            }
            
            # Add the member as a custom object with DisplayName and Mail
            $activeUsersPerSG[$securityGroup] += [PSCustomObject]@{
                DisplayName = $member.DisplayName
                Mail        = $member.Mail
            }
        }
    }
}

# Prepare results for Excel export
$exportData = @()

foreach ($securityGroup in $activeUsersPerSG.Keys) {
    foreach ($member in $activeUsersPerSG[$securityGroup]) {
        $exportData += [PSCustomObject]@{
            SecurityGroup = $securityGroup
            DisplayName   = $member.DisplayName
            Mail          = $member.Mail
        }
    }
}

# Export results to Excel
$excelFilePath = "C:\"
Write-Output "Exporting results to Excel..."
$exportData | Export-Excel -Path $excelFilePath -WorksheetName "ActiveUsersPerSG" -AutoSize -AutoFilter

Write-Output "Exported SGs and their members ordered in alphabetical order to $excelFilePath"
