# Connect-ExchangeOnline
$SourceUser = Read-Host "Enter the email address of who you want to mirror FROM"    
$TargetUser = Read-Host "Enter the email of the address you want to mirror TO"

$DistributionGroups = Get-DistributionGroup -ResultSize Unlimited | where {!$_.GroupType.contains("SecurityEnabled")}

$GroupsToMirror = $DistributionGroups | Where-Object { (Get-DistributionGroupMember $_.Name -ResultSize Unlimited | foreach {$_.PrimarySMTPAddress}) -Contains $SourceUser} | select DisplayName, PrimarySMTPAddress

Write-Host "`nThese are the distribution lists that $SourceUser is a member of:`n"
$GroupsToMirror | Format-Table -AutoSize
[void][System.Console]::Out.Flush() # Force console flush

# Start-Sleep 3

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

