### CONFIG ###
$OutPath = '.\Report.csv'

$UserProperties = @(
    'Name',
    'GivenName',
    'Surname',
    'SamAccountName'
)

$GroupNames = @(
    'Citrix_Office2007_*',
    'Citrix_Sharepoint'
)

$ExcludeGroupNames = @(
    'TechAdmins'
)

$ExcludeOUNames = @(
    'deaktiviert',
    'Administration',
    "Aushilfen",
    "Users",
    '_Airwatch',
    '_Cognos',
    '_CTI',
    '_ELO',
    '_Iris',
    '_Navision',
    '_Niederlassungen',
    '_PTV',
    '_Ressourcen',
    '_ServiceAccounts',
    '_Sharepoint',
    '_Technik',
    '_User Help Desk',
    '_vCloud',
    '_Weitere'
)


(Get-Item -Path ".\" -Verbose).FullName


### RUN ###
. ".\Get-UserReport.ps1"
Get-UserReport `
    -UserProperties $UserProperties -OutPath $OutPath `
    -GroupNames $GroupNames -ExcludeGroupNames $ExcludeGroupNames `
    -ExcludeOUNames $ExcludeOUNames
