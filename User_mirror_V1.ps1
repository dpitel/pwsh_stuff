# Reading stdin to grab appropriate TenantId and domain in order to connect to the EXO and AAD modules
$TntID = Read-Host "Please enter the tenant ID of the organization you're attempting to connect to"
$DelOrg = Read-Host "Please enter the domain of the organization that you're attempting to connect to" 

# Connecting to AAD/EXO modules
Connect-AzureAD -TenantId $TntID
Connect-ExchangeOnline -DelegatedOrganization $DelOrg


# Input source and target users
$SourceUser = Read-Host "Enter the email/UPN of the user you'd like to mirror from"
$TargetUser = Read-Host "Enter the email/UPN of the user who you'd like to add new group memberships to"

# Grabbing ObjectId for the target user- we need the ObjectId b/c AAD is only able to use the ObjectId for mirroring, while EXO using the DisplayName
$TargetUserObject = Get-AzureADUser -Filter "UserPrincipalName eq '$TargetUser'"
if (-not $TargetUserObject) {
    Write-Error "Target user not found in Azure AD."
    return
}
$TargetUserObjectId = $TargetUserObject.ObjectId

# Getting groups for the source user
$SourceGroups = Get-AzureADUserMembership -ObjectId $SourceUser | Where-Object ObjectType -eq 'Group'

# Processing/mirring group membership for Entra/AAD groups
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

# Grabbing all non-security enabled groups from EXO and stuffing them into variable
$DistributionGroups = Get-DistributionGroup -ResultSize Unlimited | Where-Object {!$_.GroupType.contains("SecurityEnabled")}

# Grabbing all groups to mirror from the source user
$GroupsToMirror = $DistributionGroups | Where-Object { (Get-DistributionGroupMember $_.Name -ResultSize Unlimited | ForEach-Object {$_.PrimarySMTPAddress}) -Contains $SourceUser} | select DisplayName, PrimarySMTPAddress

# Proccessing/mirroring all EXO groups from source to target user
foreach ($Group in $GroupsToMirror) {
Write-Output "Adding $TargetUser to group $($Group.DisplayName)"
Add-DistributionGroupMember -Identity $Group.DisplayName -Member $TargetUser
}

# Messages to user to stdout
Write-Output "$TargetUser has been added to all the requested distribution groups"

Write-Host "Processing completed for all groups- have a nice day!"
