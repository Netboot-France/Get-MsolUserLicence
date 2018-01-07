<#PSScriptInfo
    .VERSION 1.0.4
    .GUID c9c0f8f8-d4ae-45a0-803c-3a6e1cb5c834
    .AUTHOR thomas.illiet
    .COMPANYNAME netboot.fr
    .COPYRIGHT (c) 2017 Netboot. All rights reserved.
    .TAGS Office365
    .LICENSEURI https://raw.githubusercontent.com/Netboot-France/Get-MsolUserLicence/master/LICENSE
    .PROJECTURI https://github.com/Netboot-France/Get-MsolUserLicence
    .ICONURI https://raw.githubusercontent.com/Netboot-France/Get-MsolUserLicence/master/ICON.png
    .EXTERNALMODULEDEPENDENCIES Msol
    .REQUIREDSCRIPTS 
    .EXTERNALSCRIPTDEPENDENCIES 
    .RELEASENOTES
#> 

<#  
    .DESCRIPTION  
        This script provides a report that shows license allocation in Office 365.
        
    .NOTES  
        File Name   : Get-MsolUserLicence.ps1
        Author      : Thomas ILLIET, contact@thomas-illiet.fr
        Date        : 2017-11-03
        Last Update : 2018-01-07
        Version     : 1.0.4

    .PARAMETER UserprincipalName
        Speicifies the user ID of the user to retrieve.

    .Parameter LicenceFile
        Json licence database file ( you can find example file in my repository )

    .EXAMPLE
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

    .EXAMPLE
        Get-MsolUser | Get-MsolUserLicence

        DisplayName          UserPrincipalName                                          Power-BI_Standard O365_BUSINESS_ESSENTIALS
        -----------          -----------------                                          ----------------- ------------------------
        Unicorn Girl         unicorn.girl_microsoft.fr#EXT#@netboot.onmicrosoft.com                  True                    False
        Thomas ILLIET        contact@thomas-illiet.fr                                                True                     True
#>


[cmdletbinding()]
Param (
    # UserPrincipalName
    [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    $UserPrincipalName,

    # File for custom SKU conversion
    [Parameter(Mandatory=$False)]
    [String]$LicenceFile
)

Begin {
    function Get-LicenseName
    {
        Param(
            [String]$Sku,
            [String]$LicenceFile
        )
        # Check Licence File is defined
        if(-not([string]::IsNullOrEmpty($LicenceFile)))
        {
            # Load Licence File
            Try
            {
                $LicenseName = @{}
                $CsvFile = Get-Content -Raw -Path $LicenceFile
                (ConvertFrom-Json $CsvFile).psobject.properties | Foreach { $LicenseName[$_.Name] = $_.Value }
            }
            Catch
            {
                throw "Unable to load LicenceFile ! "
            }
        }
        else
        {
            # Licence Name
            $LicenseName = @{
                "POWER_BI_STANDARD"             = "Power-BI_Standard"
                "MCOMEETADV"                    = "PSTN_conferencing"
                "EMS"                           = "Enterprise_Mobility_Suite"
                "DESKLESSPACK"                  = "Office_365_(Plan_K1)"
                "DESKLESSWOFFPACK"              = "Office_365_(Plan_K2)"
                "LITEPACK"                      = "Office_365_(Plan_P1)"
                "EXCHANGESTANDARD"              = "Office_365_Exchange_Online_Only"
                "STANDARDPACK"                  = "Office_365_(Plan_E1)"
                "STANDARDWOFFPACK"              = "Office_365_(Plan_E2)"
                "ENTERPRISEPACK"                = "Office_365_(Plan_E3)"
                "ENTERPRISEPACKLRG"             = "Office_365_(Plan_E3)"
                "ENTERPRISEWITHSCAL"            = "Office_365_(Plan_E4)"
                "O365_BUSINESS_ESSENTIALS"      = "Office_365_Business_Essentials"
            }
        }
        
        # Search Licence by sku name
        if($LicenseName.($sku))
        {
            return $LicenseName.($sku)
        }
        else
        {
            Write-Debug "Sku name ($sku) is not defined"
            return $sku
        }
    }

    #----------------------------------------------
    # Create Template Object
    #----------------------------------------------
    $licensetype = Get-MsolAccountSku | Where {$_.ConsumedUnits -ge 1}

    $TemplateObject = [PsCustomObject]@{
        DisplayName       =$null
        UserPrincipalName =$null
    }

    # Loop through all licence types found in the tenant
    foreach ($license in $licensetype.AccountSkuId) 
    {
        $Name = Get-LicenseName -Sku $license.split(':')[1] -LicenceFile $LicenceFile
        $TemplateObject | Add-Member -Name $Name -Type NoteProperty -Value $false
    }
}


Process  {
    #----------------------------------------------
    # Get All users
    #----------------------------------------------
    if(-not([string]::IsNullOrEmpty($UserPrincipalName)))
    {
        $Users = $UserPrincipalName
    }
    else
    {
        $Users = Get-MsolUser -All | where {$_.isLicensed -eq "True"} | select DisplayName, UserPrincipalName, isLicensed, Licenses
    }

    #----------------------------------------------
    # Create Report Object
    #----------------------------------------------
    $ReturnObject=@()
    foreach($User in $Users)
    {
        $UserObject = $TemplateObject.PsObject.Copy()

        # Set User information
        $UserObject.DisplayName = $User.DisplayName
        $UserObject.UserPrincipalName = $User.UserPrincipalName

        # Define Licence Attribution
        foreach($License in $User.Licenses.AccountSkuId)
        {
            $Name = Get-LicenseName -Sku $license.split(':')[1] -LicenceFile $LicenceFile
            $UserObject.($Name) = $true
        }

        # Add Object to return store
        $ReturnObject += $UserObject
    }
    return $ReturnObject
}