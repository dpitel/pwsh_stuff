# Connect to AzureAD
# Connect-AzureAD
# Uncomment and replace with your TenantId if needed
# Connect-AzureAD -TenantId <Your-Tenant-ID>

# Getting list of all users in the tenant
Get-AzureADUser -All $true | Select-Object UserPrincipalName, ObjectId

# Choosing user to copy group memberships FROM
$SourceUser = Read-Host "Please enter the email address/UPN of the user you'd like to mirror from"

# Choosing user to copy the group memberships TO
$TargetUser = Read-Host "Please enter the email address/UPN of the user to add new group memberships to"

# Retrieve the user object for the target user to get their ObjectId
$TargetUser_ObjectID = (Get-AzureADUser -Filter "UserPrincipalName eq '$TargetUser'").ObjectId

# Retrieve the source user's group memberships
$SourceGroups = Get-AzureADUserMembership -ObjectId $SourceUser | Where-Object {$_.ObjectType -eq 'Group'}

# Adding groups to the target user
foreach ($Group in $SourceGroups) {
    $GroupId = $Group.ObjectId
    Write-Host "Adding Target User to Group: $($Group.DisplayName)"
    try {
        Add-AzureADGroupMember -ObjectId $GroupId -RefObjectId $TargetUser_ObjectID
        Write-Host "Successfully added to group: $($Group.DisplayName)"
    } catch {
        Write-Warning "Failed to add to group: $($Group.DisplayName). Error: $_"
    }
}

Write-Host "`nAll group memberships mirroring complete!"

# Export-ModuleMember -Variable 'GroupId'