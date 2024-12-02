# Connect to specified tenant/org in EXO and AzureAD

$TntID = Read-Host "Please enter the tenant ID of the organization you're attempting to connect to:"
$DelOrg = Read-Host "Please enter the domain of the organization that you're attempting to connect to: " 

Connect-AzureAD -TenantId $TntID
Connect-ExchangeOnline -DelegatedOrganization $DelOrg