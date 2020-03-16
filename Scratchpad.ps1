$OUList=Get-ADOrganizationalUnit -Filter * -Server $ADSErver -SearchBase $BaseOU | where-Object {$_.LinkedGroupPolicyObjects -notlike ""}
$OUList | ogv

Write-Host "This could take a while, hang in there.  $($OUList.Count) found..."

# Get Unique GPOs and their details

$GPO_Unique = $OUList | Select-Object -ExpandProperty LinkedGroupPolicyObjects | Select-Object -Unique 
$GPO_Unique.count
$GPO_Unique | OGV

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

$GPODetails = $Results
$GPODetails | ogv

# GOPs Links

$GPOLinks = foreach ($OU in $OUList){
    $Members = $OU | Select-Object -ExpandProperty LinkedGroupPolicyObjects
    $Members | Select-Object -Property `
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
$GPOLinks | OGV


$Results = @()
foreach($OU in $OUList){
    $LinkedGPOs = Get-ADOrganizationalUnit -Identity $OU -Server $ADSErver | Select-Object -ExpandProperty LinkedGroupPolicyObjects           
           
    foreach($LinkedGPO in $LinkedGPOs) {            
        $GPO = [adsi]"LDAP://$LinkedGPO" | select *  
       
        $properties = @{
        OUName=$OU.DistinguishedName
        GPOName=$GPO.displayName.Value
        GPOGUID=$GPO.Guid
        GPOWhenCreated=$gpo.whenChanged.Value
        GPOWhenChanged = $gpo.whenChanged.Value
       
        }
        Write-Host "GPO Name: $($GPO.displayName.Value) GPODN:$($OU.DistinguishedName)"
    
        $Results += New-Object psobject -Property $properties
     }
}       