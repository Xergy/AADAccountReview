# Simple Script to Export Vital AzureAD Users, Groups, and Group Members for Human Review

#Connect to Azure AD
try 
{ $var = Get-AzureADTenantDetail } 
catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationExcetion] 
{ Write-Host "You're not connected."; Connect-AzureAD -AzureEnvironmentName AzureUSGovernment}

# Variables
$ADGroupSearchString = "demo"
$LogfilePath = ".\Results"

Write-Host "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Starting AzureADInfo..."

#Get all IAM Groups
Write-Host "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Gathering Groups..."
$AADGroups = Get-AzureADGroup -SearchString $ADGroupSearchString | Sort-Object -Property DisplayName

#Get all Group Members
Write-Host "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Gathering Group Members..."

$AADGroupMembers = foreach ($AADGroup in $AADGroups){
    $Members = $AADGroup | Get-AzureADGroupMember | Select-Object objectId,ObjectType,DisplayName,UserPrincipalName
    $Members | Select-Object -Property ObjectId,DisplayName,
        @{N='GroupObjectId';E={
                $AADGroup.ObjectId
            }
        },
        @{N='GroupDisplayName';E={
            $AADGroup.DisplayName
            } 
        } | Sort-Object -Property GroupDisplayName  
}

# Find Unique Members
Write-Host "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Finding All Unique Members Group Members..."
$AADGroupMemberUnique = $AADGroupMembers | Select-Object -Property DisplayName,ObjectId -Unique | Sort-Object -Property DisplayName

# Get Member Details
Write-Host "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Gathering Detailed User Info Based on Group Members..."
$Users = $AADGroupMemberUnique | Get-AzureADUser -ErrorAction Ignore
# $Users | OgV

# Filter Objects

$UsersFiltered = $Users | Select-Object -Property DisplayName,ObjectId,UserPrincipalName,AccountEnabled,GivenName,Surname,JobTitle,MailNickName
$GroupsFiltered = $AADGroups | Select-Object -Property DisplayName,ObjectId,MailNickName,SecurityEnabled
$GroupMembersFiltered = $AADGroupMembers | Select-Object -Property GroupDisplayName,GroupObjectId,ObjectId,DisplayName  


Write-Host "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Exporting Data to $()..."
$NowStr = Get-Date -Format yyyy-MM-ddTHH.mm.fff

mkdir "$($LogfilePath)\AzureADInfo" -ErrorAction SilentlyContinue | Out-Null
mkdir "$($LogfilePath)\AzureADInfo\$($NowStr)_AzureADInfo" -ErrorAction SilentlyContinue | Out-Null

Write-Host "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Exporting Data to $($LogfilePath)\AzureADInfo\$($NowStr)_AzureADInfo..."

$UsersFiltered  | Export-Csv -Path "$($LogfilePath)\AzureADInfo\$($NowStr)_AzureADInfo\$($NowStr)_AzureADInfo_Users.csv" -NoTypeInformation
$GroupsFiltered  | Export-Csv -Path "$($LogfilePath)\AzureADInfo\$($NowStr)_AzureADInfo\$($NowStr)_AzureADInfo_Groups.csv" -NoTypeInformation
$GroupMembersFiltered  | Export-Csv -Path "$($LogfilePath)\AzureADInfo\$($NowStr)_AzureADInfo\$($NowStr)_AzureADInfo_GroupMembers.csv" -NoTypeInformation

Write-Host "$(Get-Date -Format yyyy-MM-ddTHH.mm.fff) Done!"

