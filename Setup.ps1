#requires -version 2

<#
.SYNOPSIS
    Setup

.DESCRIPTION
    Set up folders structure.

.NOTES
    Version: 0.1
    Author: Erforschr
    License: MIT License
    Creation Date: 01/08/2019
#>

#---[Imports and preferences]----------------------------------------------------------------------

$ErrorActionPreference = 'Stop' # Continue SilentlyContinue Stop 


#---[Variables]------------------------------------------------------------------------------------

$ScriptPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)


#---[Create folders structure]---------------------------------------------------------------------

Write-Host "Setting folders structure up"

$Folders = @(
    'Inventories',
    'Drafts',
    'Policies',
    'Inspections'
    )

ForEach ($Folder in $Folders) {
    If(-not (Test-Path $([System.String]::Format("{0}\{1}", $ScriptPath, $Folders)) -PathType 'Container'))
    {
	    $Path = [System.String]::Format("{0}\{1}", $ScriptPath, $Folder)
        $t = [System.IO.Directory]::CreateDirectory($Path)
        
        Write-Host "Create folder: $Folder"
    }
}

Write-Host ""
