# Get-MsolUserLicence

![Demo](Resource/Demo.gif)

## SYNOPSIS  
This script provides a report that shows license allocation in Office 365.

## NOTES  
  - **File Name**   : Get-MsolUserLicences.ps1
  - **Author**      : Thomas ILLIET, contact@thomas-illiet.fr
  - **Date**        : 2017-11-03
  - **Last Update** : 2018-01-08
  - **Version**     : 1.0.5

## Install
```
Install-Script -Name Get-MsolUserLicence
```

## EXEMPLE
``` 
Get-MsolUserLicence -UserPrincipalName "unicorn@microsoft.com"

    DisplayName               : Unicorn Girl
    UserPrincipalName         : unicorn@microsoft.com
    STREAM                    : False
    Office 365 (Plan E3)      : False
    FLOW_FREE                 : False
    POWERAPPS_VIRAL           : False
    Power-BI Standard         : False
    Enterprise Mobility Suite : True
    (PSTN) conferencing       : False
    Office 365 (Plan E1)      : True
```

```
Get-MsolUser | Get-MsolUserLicences

DisplayName          UserPrincipalName                                          Power-BI_Standard O365_BUSINESS_ESSENTIALS
-----------          -----------------                                          ----------------- ------------------------
Unicorn Girl         unicorn.girl_microsoft.fr#EXT#@netboot.onmicrosoft.com                  True                    False
Thomas ILLIET        contact@thomas-illiet.fr                                                True                     True
```