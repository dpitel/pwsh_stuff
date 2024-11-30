# Connect to AzureAD
# Connect-AzureAD -TenantId <Tenant-ID>

# Input source and target users
$SourceUser = Read-Host "Enter the ObjectId of the user you'd like to mirror from"
$TargetUser = Read-Host "Enter the email address of the user who you'd like to add new group memberships to"

# Retrieve ObjectId for the target user
$TargetUserObject = Get-AzureADUser -Filter "UserPrincipalName eq '$TargetUser'"
if (-not $TargetUserObject) {
    Write-Error "Target user not found in Azure AD."
    return
}
$TargetUserObjectId = $TargetUserObject.ObjectId

# Get groups for the source user
$SourceGroups = Get-AzureADUserMembership -ObjectId $SourceUser | Where-Object ObjectType -eq 'Group'

# Process group membership
foreach ($Group in $SourceGroups) {
    $GroupId = $Group.ObjectId
    $GroupName = $Group.DisplayName

    try {
        Add-AzureADGroupMember -ObjectId $GroupId -RefObjectId $TargetUserObjectId
        Write-Host "Successfully added $TargetUser to group: $GroupName"
    } catch {
        # Filter expected errors
        if ($_.Exception.Message -match "Cannot Update a mail-enabled security group" -or
            $_.Exception.Message -match "Insufficient privileges to complete the operation") {
            # Suppress expected errors
            continue
        } else {
            # Display unexpected errors
            Write-Warning "Unexpected error while processing group: $GroupName. Error: $($_.Exception.Message)"
        }
    }
}
Write-Host "Processing completed."
