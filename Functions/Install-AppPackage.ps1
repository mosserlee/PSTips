# requires -version 4.0

#
# Description: 
#  Install windows store app package as development mode.
#
# Steps:
#   1. Find the app appxbundle file in the script directory.
#   2. Extract the appx file, and copy it in local APPData pakcage folder.
#   3. Install the package as development mode.
# 
# Author: 
# Mosser Lee (http://www.pstips.net)
#

#
# Find a appx bundle file from current package.
#
function Find-Appxbundle
{
    $appxbundleFiles = dir -File $CurrentDir -filter *.appxbundle
    if($appxbundleFiles -ne $null)
    {
        return $appxbundleFiles.FullName
    }
    else{
        return $null
    }
}


#
# Unzip zip package.
#
Function Unzip-File
{
    param([string]$ZipFile,[string]$TargetFolder)
    if(!(Test-Path $TargetFolder))
    {
     mkdir $TargetFolder
    }
        $shellApp = New-Object -ComObject Shell.Application
        $files = $shellApp.NameSpace($ZipFile).Items()    
        $shellApp.NameSpace($TargetFolder).CopyHere($files,4)
}

#
# Unzip appx bundle file.
#
Function Unzip-Appxbundle()
{
    # the root directory of installation.
    $packageInstallPath = "$env:LOCALAPPDATA\Packages\$([guid]::NewGuid())"
    mkdir $packageInstallPath | Out-Null
    Copy-Item $AppxbundleSource $packageInstallPath
   
    # appx bundle package.
    $packageFile = Join-Path $packageInstallPath  (Get-Item $AppxbundleSource).Name

    # rename bundle package's extension name to ".zip".
    $oldBundleItem = Get-Item $packageFile
    $tempBundleFileName = $oldBundleItem.BaseName + ".zip"
    Rename-Item $oldBundleItem -NewName $tempBundleFileName
    $tempBundleFile = "$packageInstallPath\$tempBundleFileName"

    # unzip bundle package
    $tempBundleDir = Join-Path $packageInstallPath ([guid]::NewGuid())
    mkdir $tempBundleDir | Out-Null
    Unzip-File -ZipFile $tempBundleFile -TargetFolder $tempBundleDir
    
    # get appx file name from appx metadata file direcoty.
    $appxBundleManifest = [xml](Get-Content "$tempBundleDir\AppxMetadata\AppxBundleManifest.xml" -Raw)
    $pkg = $appxBundleManifest.Bundle.Packages.Package | where { $_.Type -eq "application" }
    $appxFileName = $pkg.FileName
    
    # rename appx file to zip file,and unzip it to the root directory of installation.
    $appxZipFileName = $appxFileName -replace ".appx" , ".zip"
    $appxFile = "$tempBundleDir\$appxFileName"
    Get-Item $appxFile | Rename-Item -NewName $appxZipFileName
    $appxFile = "$tempBundleDir\$appxZipFileName"
    Unzip-File -ZipFile $appxFile -TargetFolder $packageInstallPath 

    # remove temp bundle directory and bundle file
    Remove-Item $tempBundleDir -Force -Recurse
    Remove-Item $tempBundleFile -Force

    # return package installation path
    return $packageInstallPath
}

#
# Print message and exit.
#
Function PrintMessageAndExit
{
    param(
    [string]$Message,
    [switch]$Success,
    [switch]$Failed
    )
    $foreColor = $host.UI.RawUI.ForegroundColor
    if($Success) 
    { 
        $foreColor ="green"
     }
    else
    { 
        $foreColor = "yello"
     }

    if($message) {
        Write-Host $message -ForegroundColor $foreColor
    }
    Read-Host "Press Enter to exit"
    exit 0
}

#
# Is current script was run as admin.
#
function IsRunAsAdmin()
{
    $currentWi = [Security.Principal.WindowsIdentity]::GetCurrent()
    $currentWp = [Security.Principal.WindowsPrincipal]$currentWi
    return $currentWp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

#
# Checks whether the machine is missing a valid developer license.
#
function CheckIfNeedDeveloperLicense
{
    $Result = $false
    do{
        try
        {
            $Result = ( Get-WindowsDeveloperLicense | Where-Object { $_.IsValid } ).Count -gt 0
        }
        catch 
        {
        }

        if( -not $Result ) 
        {
            $options = [System.Management.Automation.Host.ChoiceDescription[]]@( "&Yes","&No" )
            $optionsMsg = "No windows developer license found on your computer, need to acquire, are your sure to continue? "
            $Answer = $host.UI.PromptForChoice( "",  $optionsMsg , $options, 1)
            if($Answer -eq 1)
            {
                PrintMessageAndExit 'User Canceled the installation.'
            }
            else
            {
                # Acquiring developer license
                Write-Host 'Acquiring developer license...'
                if(IsRunAsAdmin) {
                    Show-WindowsDeveloperLicenseRegistration
                }
                else{
                    Start-Process 'PowerShell.exe' " & {Show-WindowsDeveloperLicenseRegistration}" -Verb runas -Wait
                }
            }
        }

    }
    while( -not $Result)
}

#
# Detect old version app.
#
function Test-OldVersionApp
{
    # detect old version app.
    $oldApp = Get-AppxPackage -Name $AppName
    if($oldApp) 
    {
        $optionsMsg = 'App has already installed, you need to uninstall it firstly, are your sure to continue?'
        $options =  [System.Management.Automation.Host.ChoiceDescription[]]@('&Yes','&No')
        $Answer = $host.UI.PromptForChoice( "" ,$optionsMsg, $options, 1)
        if($Answer -eq 1)
        {
            PrintMessageAndExit 'User Canceled the installation.'
        }
        else{
            $oldApp | Remove-AppxPackage
        }
    }
}

#
# Install package.
#
function Install-AppPackage
{
    # Check developer license.
    CheckIfNeedDeveloperLicense

    # Test old version app
    Test-OldVersionApp

    # Find appx bundle file
	Write-Host 'In preparation ...'
    $AppxbundleSource = Find-Appxbundle Packages
    if($AppxbundleSource -eq $null) {
    PrintMessageAndExit -Message "No appx bundle file found, your app installation failed." -Failed
    }

    $packagePath = Unzip-Appxbundle

    # Install package
    $manifestFile = "$packagePath\AppxManifest.xml"
    Add-AppxPackage -Register $manifestFile -ForceApplicationShutdown
    if($?){
      PrintMessageAndExit -Message "Your app was successfully installed." -Success
    }
    else{
      PrintMessageAndExit -Message "Your app installation failed." -Failed
    }
}

#
# Main script entry point
#

$ErrorActionPreference='stop'

# app Name
$AppName = 'AppName' 
# TODO: read name from manifest file.

# current directory.
$CurrentDir = Split-Path $MyInvocation.InvocationName -Parent

# Install package
Install-AppPackage