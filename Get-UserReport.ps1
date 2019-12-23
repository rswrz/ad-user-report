Function Get-UserReport {
  PARAM(
    [Parameter(ValuefromPipeline=$true,mandatory=$true)][String[]] $GroupNames,
    [String[]] $UserProperties,
    [String[]] $ExcludeGroupNames,
    [String[]] $ExcludeOUNames,
    [String] $OutPath
  )

  BEGIN {

    #
    # All results will be saved here
    #
    #[System.Collections.ArrayList]$Result = @()
    #$Result = New-Object PSObject
    $Result = new-object System.Collections.Generic.List[system.object]

    $GroupDNs = $GroupNames | ForEach-Object {
        Get-ADGroup -Filter { Name -like $_ } | Select-Object -ExpandProperty DistinguishedName
    }

    #
    # Expand $ExcludedGroupNames to full DNs
    #
    if ($ExcludeGroupNames) {
        $ExcludedGroupDNs = $ExcludeGroupNames | ForEach-Object {
            Get-ADGroup -Filter { Name -like $_ } | Select-Object -ExpandProperty DistinguishedName
        }
    }
    #
    # Expand $ExcludedGroupNames to full DNs
    #
    if ($ExcludeOUNames) {
        $ExcludedOUDNs = $ExcludeOUNames | ForEach-Object {
            Get-ADOrganizationalUnit -Filter { Name -like $_ } | Select-Object -ExpandProperty DistinguishedName
        }
    }

  }

  PROCESS {

    #
    # Magic^^
    #

    ForEach ($Group in $GroupDNs) {
        ForEach ($Member in (Get-ADGroupMember $Group -Recursive | Where-Object { $_.objectClass -eq 'user' })) {

            # Excluded Groups
            $MemberOf = Get-ADUser -Properties MemberOf $Member | Select-Object -ExpandProperty MemberOf
            If ($MemberOf -and $ExcludedGroupDNs -and ($(Compare-Object $MemberOf $ExcludedGroupDNs -includeequal -excludedifferent).count -gt 0)) {
                continue
            }

            # Excluded OUs
            $UserOU = 'OU'+($Member.DistinguishedName -split ",OU",2)[1]
            If ($ExcludedOUDNs -contains $UserOU) {
                continue
            }

            # Add to $Result
            #$Member | Add-Member -MemberType NoteProperty -Name 'SearchGroup' -Value (Get-ADGroup -Identity $Group -Properties Name).Name

            $ADUserObj = $Member | Get-ADUser -Properties $UserProperties

            $User = $User = New-Object PSObject
            $UserProperties | ForEach-Object `
                -Begin { $ADUserObj = $Member | Get-ADUser -Properties $UserProperties } `
                -Process { $User | Add-Member -MemberType NoteProperty -Name $_ -Value $ADUserObj[$_] }

            $User | Add-Member -MemberType NoteProperty -Name Group -Value (Get-ADGroup -Identity $Group -Properties Name).Name

            If ($Result -notcontains $User) {
                $Result += $User
            }
        }
    }
  }

  END {
    #
    # Save to CSV
    #

    $Props = @{LABEL='Anzeigename'; EXPRESSION={$_.Name.Value}},
             @{LABEL='Vorname'; EXPRESSION={$_.GivenName.Value}},
             @{LABEL='Nachname'; EXPRESSION={$_.Surname.Value}},
             @{LABEL='Anmeldename'; EXPRESSION={$_.SamAccountName.Value}},
             @{LABEL='Gruppe'; EXPRESSION={$_.Group}}

    If ($OutPath) {
        $Result | Select-Object $Props | Export-Csv -Encoding UTF8 -NoTypeInformation -Delimiter ';' -Path $OutPath
    }
    else {
        $Result | Select-Object $Props | Format-List
    }
  }
}
