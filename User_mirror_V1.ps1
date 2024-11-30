# Connect to AzureAD
# Connect-AzureAD -TenantId <Tenant-ID>
# Connect-ExchangeOnline


# Input source and target users
$SourceUser = Read-Host "Enter the email/UPN of the user you'd like to mirror from"
$TargetUser = Read-Host "Enter the email/UPN of the user who you'd like to add new group memberships to"

# Retrieve ObjectId for the target user
$TargetUserObject = Get-AzureADUser -Filter "UserPrincipalName eq '$TargetUser'"
if (-not $TargetUserObject) {
    Write-Error "Target user not found in Azure AD."
    return
}
$TargetUserObjectId = $TargetUserObject.ObjectId

# Get groups for the source user
$SourceGroups = Get-AzureADUserMembership -ObjectId $SourceUser | Where-Object ObjectType -eq 'Group'

# Process group membership for Entra/AAD groups
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

Write-Host "Processing completed for Entra/AAD groups- commencing for Exchange groups..."

$DistributionGroups = Get-DistributionGroup -ResultSize Unlimited | Where-Object {!$_.GroupType.contains("SecurityEnabled")}

$GroupsToMirror = $DistributionGroups | Where-Object { (Get-DistributionGroupMember $_.Name -ResultSize Unlimited | ForEach-Object {$_.PrimarySMTPAddress}) -Contains $SourceUser} | select DisplayName, PrimarySMTPAddress

Write-Host "`nThese are the distribution lists that $SourceUser is a member of:`n"
$GroupsToMirror | Format-Table -AutoSize
[void][System.Console]::Out.Flush() # Force console flush for timing of writing to stdout

Start-Sleep 1 # Might remove this later

$Confirm = Read-Host "Are you sure you want to proceed w/the mirroring (Y/N)?"
if ($Confirm -eq 'Y') {
    foreach ($Group in $GroupsToMirror) {
    Write-Output "Adding $TargetUser to group $($Group.DisplayName)"
    Add-DistributionGroupMember -Identity $Group.DisplayName -Member $TargetUser
    }
    Write-Output "User $TargetUser has been added to all the requested distribution groups"

} else {
    Write-Output "Mirroring Cancelled"
}

Write-Host "Processing completed for all groups- have a nice day!"
