# Connecting to AzureAD 
#Connect-AzureAD -TenantId 0ebc7067-cf0b-4f33-bf12-7df186398783 #MOAM tenant ID
#Connect-AzureAD

# Getting list of all users in the tenant
Get-AzureADUser -All $true | select DisplayName, ObjectID 

# Choosing user to copy group memberships FROM
$SourceUser = Read-Host "Please enter the ObjectID of the user you'd like to mirror from "

# Choosing user to copy the group memberships TO
$TargetUser = Read-Host "Please enter the email address of the user who you'd like to add new group memberships to "

# Retrieve the user object for the target user
$TargetUser_ObjectID = Get-AzureADUser -ObjectId $TargetUser | Select-Object ObjectId

# Source of truth membership groups
$SourceGroups = Get-AzureADUserMembership -ObjectId $SourceUser | Where-Object ObjectType -EQ Group

# Adding groups to target user
foreach ($group in $SourceGroups) {
    $groupId = $group.ObjectId
    Write-Output "Working- please stand by..."
    Add-AzureADGroupMember -ObjectId $groupId -RefObjectId $TargetUser_ObjectID
}




