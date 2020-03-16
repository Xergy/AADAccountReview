<#
.Synopsis
   Powershell Script to get details AD reports
.DESCRIPTION
   script fetches below reports
   -> User Details
   -> Computer Object Details
   -> GPO Details
   -> Group Details

.NOTES    
    Name: AD_Info.ps1
    Author: Jonathan Core
    Email : jcore@microsoft.com
    Updater: Raffe Felts
    Email : raffe@microsoft.com
    Version: 1.0
    DateCreated: 03 Dec 2019
#>


$OutputFolder = ".\Results\ADInfo"
$BaseOU = "OU=ACME,DC=dev1,DC=corp,DC=com"
$ADServer = "ADServerName.fqdn.com"

# Load PowerShell module for Active Directory
try{

Import-Module ActiveDirectory

#date  
$date = $(Get-Date -Format yyyy-MM-ddTHH.mm.fff)
#path
$path = $outputfolder + "\$($date)_ADInfo"

if (!(Test-path $path))
{
md $path | Out-Null
}

}
catch 
{
Write-Host "Issue while creating the folder Exception : $_.Exception.Message "
}

Write-Host -ForegroundColor Green "!! Collecting Active Directory data... !!"

#Convert time values to readable format
$hash_badPasswordTime = @{Name="pwdLastSet";Expression={([datetime]::FromFileTime($_.badPasswordTime))}}
$hash_lastLogonTimestamp = @{Name="LastLogonTimeStamp";Expression={([datetime]::FromFileTime($_.LastLogonTimeStamp))}}


Write-Host "--------------------------------------------------------------"
Write-Host "Gathering User details..."
Write-Host "--------------------------------------------------------------"
#Get user accounts details
$selection = "Name", "SamAccountName","ObjectSid", "adminCount","Enabled", "UserPrincipalName", "whenChanged", "whenCreated", "PasswordNeverExpires", "PasswordLastSet", "PasswordNotRequired" , "UseDESKeyOnly" , "lastLogonTimestamp", "BadPwdCount" , "badPasswordTime", "DistinguishedName", "Description", "EmployeeID", "department", "division" , "Title", "Company"

$UserDetails = Get-ADUser -Server $ADServer -Filter * -SearchBase $BaseOU -Properties $selection | select Name,SamAccountName,ObjectSid,adminCount,Enabled,UserPrincipalName,whenChanged,whenCreated,PasswordNeverExpires,PasswordLastSet,PasswordNotRequired,UseDESKeyOnly,$hash_lastLogonTimestamp,BadPwdCount,$hash_badPasswordTime,DistinguishedName,Description,EmployeeID,department,division,Title,Company 

$file1 = "$path\$($date)_ADInfo_Users.csv"

$UserDetails | Export-CSV $file1 -NoClobber -NoTypeInformation
# $UserDetails | ogv


Write-Host "Gathering all Computer details..."
Write-Host "--------------------------------------------------------------"

$AllComp = Get-ADComputer -Server $ADServer -Filter * -Searchbase $BaseOU -Property Name,IPv4Address,Enabled,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion,Created,LastLogonDate,SID | Select-Object Name,IPv4Address,Enabled,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion,Created,LastLogonDate,SID
$file2 = "$path\$($date)_ADInfo_Computers.csv"
$AllComp | Export-CSV $file2 -NoClobber -NoTypeInformation


Write-Host "Gathering Group details..."
Write-Host "--------------------------------------------------------------"

$Groups = Get-ADGroup -Server $ADServer -Filter * -SearchBase $BaseOU -Properties * 
# $Groups = $Groups[0..5] # Unleash the hounds here!
Write-Host "$($Groups.count) Groups found, time for coffee. "
Write-Host "Processing Group Members... "

$GroupMembers = foreach ($Group in $Groups){
    $Members = $Group | ForEach-Object {Get-ADGroupMember -Server $ADServer -Identity $_.name} | Select-Object distinguishedName,Name,objectClass,objectGUID,SamAccountName,SID,ProtectedFromAccidentalDeletion
    Write-Host "Group $($Group.Name) has $($Members.count) Members to process... "
    $Members | Select-Object -Property *,
        @{N='GroupObjectGUID';E={
                $Group.ObjectGUID
            }
        },
        @{N='GroupName';E={
            $Group.Name
            } 
        } | Sort-Object -Property Name            
        

} 

$file3 = "$path\$($date)_ADInfo_GroupDetails.csv"
$file4 = "$path\$($date)_ADInfo_GroupsMembers.csv"    

$Groups_Filter = $Groups | Select-Object -Property Name,DisplayName,DistinguishedName,SID,ObjectGUID,ProtectedFromAccidentalDeletion,ManagedBy,whenChanged,whenCreated
$Groups_Filter | Export-CsV -Path $file3 -NoClobber -NoTypeInformation
# $Groups_Filter | ogv

$GroupMembers = $GroupMembers | Select-Object -Property GroupName,GroupObjectGUID,distinguishedName,Name,objectClass,objectGUID,SamAccountName | Sort-Object -Property GroupName,Name
$GroupMembers | Export-CsV -Path $file4 -NoClobber -NoTypeInformation
# $GroupMembers  | ogv
 

Write-Host "--------------------------------------------------------------"
Write-Host "Gathering all the OU details..."
Write-Host "--------------------------------------------------------------"
#Get All OU details

$AllOU = Get-ADOrganizationalUnit -Server $ADSErver -Filter * -SearchBase $BaseOU -Property DistinguishedName,Name,ProtectedFromAccidentalDeletion,CanonicalName | Select-Object DistinguishedName,Name,ProtectedFromAccidentalDeletion,CanonicalName
$file5 = "$path\$($date)_ADInfo_OUs.csv"
$AllOU | Export-Csv $file5 -NoClobber -NoTypeInformation
 
Write-Host "Gathering GPO details..."
Write-Host "--------------------------------------------------------------"

$OUList = Get-ADOrganizationalUnit -Filter * -Server $ADSErver -SearchBase $BaseOU | where-Object {$_.LinkedGroupPolicyObjects -notlike ""}

Write-Host "This could take a while, hang in there. Found $($OUList.Count) OUs to process..."

# Get Unique GPOs and their details

$GPO_Unique = $OUList | Select-Object -ExpandProperty LinkedGroupPolicyObjects | Select-Object -Unique 
# $GPO_Unique | OGV

$Results = @()
foreach($LinkedGPO in $GPO_Unique) {            
    $GPO = [adsi]"LDAP://$LinkedGPO" 
 
    $properties = @{
    Name=$GPO.displayName.Value
    DN=$LinkedGPO
    GUID=$GPO.Guid
    WhenCreated=$gpo.whenChanged.Value
    whenChanged = $gpo.whenChanged.Value
  
    }
    Write-Host "GPO Name: $($GPO.displayName.Value) GPODN:$($OU.DistinguishedName)"
    $Results += New-Object psobject -Property $properties
}

$GPODetails = $Results | Select-Object -Property  Name,GUID,DN,WhenCreated,whenChanged | Sort-Object -Property Name
# $GPODetails | ogv

$file6 = "$path\$($date)_ADInfo_GPODetails.csv"
$GPODetails | Export-Csv $file6 -NoClobber -NoTypeInformation

# GPOs Links

Write-Host "Processing GPO Links..."
$GPOLinks = foreach ($OU in $OUList){
    
    $Links = $OU | Select-Object -ExpandProperty LinkedGroupPolicyObjects
    $Links | Select-Object -Property `
        @{N='GPODN';E={
                $_
            }
        },
        @{N='GPOName';E={
                $_ | ForEach-Object { 
                    $GPODN = $_
                    $GPODetails | Where-Object { $_.DN -eq $GPODN } | Select-Object -Property Name | ForEach-Object {$_.Name} }
            }
        },
        @{N='OUName';E={
                $OU.Name
            }
        },
        @{N='OUDN';E={
            $OU.DistinguishedName
            } 
        } 
} 

$GPOLinks = $GPOLinks | Select-Object GPOName,GPODN,OUName,OUDN | sort-object -Property GPOName,OUDN
# $GPOLinks | ogv

$file7 = "$path\$($date)_ADInfo_GPOLinks.csv"
$GPOLinks | Export-Csv $file7 -NoClobber -NoTypeInformation

Write-Host "--------------------------------------------------------------"
Write-Host "Done!"
Write-Host "--------------------------------------------------------------"
