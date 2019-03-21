#requires -version 2

<#
.SYNOPSIS
    AppLocker Inventory

.DESCRIPTION
    List files on computer/folder and execute cmdlet "Get-AppLockerFileInformation" on listed files. By defaut a full scan is launched.

.PARAMETER FilesList
    Files list from a previous scan.

.PARAMETER ScanName
    Tag on the ouput files name.

.PARAMETER FolderToScan
    Folder to scan. Can be used for scanning a specific application.

.OUTPUTS
    Files: List of file on computer/folder.
    Inventory: List of AppLocker file information collected.

.NOTES
    Version: 0.1
    Author: Erforschr
    License: MIT License
    Creation Date: 01/08/2019
  
.EXAMPLE
    .\AppLockerInventory.ps1

.EXAMPLE
    .\AppLockerInventory.ps1 -Fileslist .\Files_<Computer>_FullScan_2019-XX-XX_XX-XX.txt

.EXAMPLE
    .\AppLockerInventory.ps1 -ScanName Oracle -FolderToScan 'C:\Program Files\Oracle'

.EXAMPLE
    .\AppLockerInventory.ps1 -ScanName Oracle -FilesList .\Files_<Computer>_Oracle_2019-XX-XX_XX-XX.txt
#>


#---[Parameters]-----------------------------------------------------------------------------------

Param (
    [ValidateScript({
        $FileObj = Get-Item $_
        
        If(-Not ($FileObj.FullName | Test-Path -PathType 'Container'))
        {
            throw "Parameter 'FolderToScan' is not a valid path"
        }
    
        return $true
    })]
    [System.IO.FileInfo]
    $FolderToScan
    ,
    [String]
    $ScanName = 'Scan'
    ,
    [ValidateScript({
        $FileObj = Get-Item $_

        If(-Not ($FileObj.FullName | Test-Path -PathType 'Leaf'))
        {
            throw "File not found"
        }
        If (-Not ($FileObj.FullName -Like '*.txt'))
        {
            throw "File is not a .txt file"
        }
        
        return $true
    })]
    [System.IO.FileInfo]
    $FilesList
)


#---[Imports and preferences]----------------------------------------------------------------------

Import-Module AppLocker

$ErrorActionPreference = 'Stop' # Continue SilentlyContinue Stop 


#---[Variables]------------------------------------------------------------------------------------

$Date = $(Get-Date).ToString("yyyy-MM-dd_HH-mm")

$ScriptPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)

$ComputerName = $env:computername


#---[Inventory files]------------------------------------------------------------------

# Get list of folders to scan
$Folders = New-Object System.Collections.ArrayList

If ($FolderToScan)
{
    $t = $Folders.Add($FolderToScan)
}
Else
{    
    $Drives = Get-PSDrive | Select-Object -ExpandProperty 'Name' | Select-String -Pattern '^[a-z]$'
    
    ForEach ($Drive in $Drives)
    {
        $Folder = [System.String]::Format("{0}:\",$Drive)
        $t = $Folders.Add($Folder)
    }
}

# Scan for files
If ($FilesList)
{
    Write-Host "Skipping folders scan"
}
Else
{
    Write-Host "Scanning folders"
    
    If ($FolderToScan)
    {
        $Files = [System.String]::Format("{0}\{1}_{2}_{3}_{4}.txt", $ScriptPath, 'Files', $ComputerName, $ScanName, $Date)
    }
    Else
    {    
        $Files = [System.String]::Format("{0}\{1}_{2}_{3}_{4}.txt", $ScriptPath, 'Files', $ComputerName, 'FullScan', $Date)
    }
    
    ForEach ($Folder in $Folders)
    {
        If ($Folder)
        {
            Write-Host "Scanning $Folder"

            $Command = [System.String]::Format("cmd.exe /c 'dir ""{0}"" /s /b /a >> {1}'",$Folder, $Files)
            Invoke-Expression -Command $Command
        }
    }
}

# Count listed files
$FileCounter = 0

If ($FilesList)
{
    $FilesListObj = Get-Item $FilesList
    $SRFiles = New-Object System.IO.StreamReader ($FilesListObj)
}
Else
{
    $SRFiles = New-Object System.IO.StreamReader ($Files)
}

While ($RLine = $SRFiles.ReadLine())
{
    $FileCounter += 1
}

Write-Host "Files listed: $FileCounter"

Write-Host ""


#---[Collect AppLocker information]----------------------------------------------------------------

Write-Host "Collecting AppLocker information"

$Inventory = [System.String]::Format("{0}\{1}_{2}_{3}_{4}.csv", $ScriptPath, 'Inventory',  $ComputerName, $ScanName, $Date)

If ($FolderToScan)
{
    $Inventory = [System.String]::Format("{0}\{1}_{2}_{3}_{4}.csv", $ScriptPath, 'Inventory',  $ComputerName, $ScanName, $Date)
}
Else
{    
    $Inventory = [System.String]::Format("{0}\{1}_{2}_{3}_{4}.csv", $ScriptPath, 'Inventory',  $ComputerName, 'FullScan', $Date)
}

$SWInventory = New-Object System.IO.StreamWriter ($Inventory)

$SWInventory.AutoFlush = $True

$Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}"";""{7}""",
"FullName",
"Extension",
"Length",
"Path",
"Publisher",
"Hash",
"SourceFileName",
"AppX")

If ($FilesList)
{
    $FilesListObj = Get-Item $FilesList
    $SRFiles = New-Object System.IO.StreamReader ($FilesListObj)
}
Else
{
    $SRFiles = New-Object System.IO.StreamReader ($Files)
}

$FileCounter = 0
$ErrorCounter = 0

While ($RLine = $SRFiles.ReadLine())
{
    Try
    {
        $File = Get-Item $RLine
        
        If ($File.Extension)
        {
            $AppLockerInfo = Get-AppLockerFileInformation -Path $File.FullName

            $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}"";""{7}""",
            $File.FullName,
            $File.Extension,
            $File.Length,
            $AppLockerInfo.Path,
            $AppLockerInfo.Publisher,
            $AppLockerInfo.Hash.HashDataString,
            $AppLockerInfo.Hash.SourceFileName,
            $AppLockerInfo.AppX
            )

            $SWInventory.WriteLine($Line)
        }
        
        $FileCounter += 1
    }
    Catch
    {
        $ErrorCounter  += 1
    }

    If ($FileCounter % 500 -eq 0) {
        Write-Host -NoNewLine "`rFile info collected: $FileCounter"
    }
}

Write-Host -NoNewLine "`rFiles info collected: $FileCounter"
Write-Host "`r`nErrors: $ErrorCounter"

Write-Host ""

$SRFiles.Close()
$SWInventory.Close()

Write-Host "Files list done: $Files"
Write-Host "Inventory done: $Inventory"

Write-Host ""
