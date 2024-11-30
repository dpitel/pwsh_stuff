Connect-ExchangeOnline
$SourceUser = "dpitel@7bxk5x.onmicrosoft.com"
$TargetUser = "kpitel@7bxk5x.onmicrosoft.com"

$DistributionGroups = Get-DistributionGroup -ResultSize Unlimited | where {!$_.GroupType.contains("SecurityEnabled")}

$DistributionGroups | Where-Object { (Get-DistributionGroupMember $_.Name -ResultSize Unlimited | foreach {$_.PrimarySMTPAddress}) -Contains "dpitel@7bxk5x.onmicrosoft.com"} | select DisplayName, PrimarySMTPAddress

$GroupsToMirror = $DistributionGroups | Where-Object { (Get-DistributionGroupMember $_.Name -ResultSize Unlimited | foreach {$_.PrimarySMTPAddress}) -Contains "dpitel@7bxk5x.onmicrosoft.com"} | select DisplayName, PrimarySMTPAddress

foreach ($Group in $GroupsToMirror) {
    Write-Output "Adding $TargetUser to group $($Group.DisplayName)"
    Add-DistributionGroupMember -Identity $Group.DisplayName -Member $TargetUser
}

Write-Output "User $TargetUser has been added to all the requested distribution groups"