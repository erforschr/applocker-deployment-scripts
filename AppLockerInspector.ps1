#requires -version 2

<#
.SYNOPSIS
    AppLocker Inspector

.DESCRIPTION
    Read AppLocker events and execute cmdlet "Get-AppLockerFileInformation" for files related to EventID 8003, 8004, 8006 and 8007.

.PARAMETER ScanName
    Tag on the ouput files name.
	
.OUTPUTS
    Events: List of AppLocker events.
	Files: List of file on computer/folder.
    Inventory: List of AppLocker file information collected.

.NOTES
    Version: 0.1
    Author: Erforschr
    License: MIT License
    Creation Date: 01/08/2019
  
.EXAMPLE
	.\AppLockerInspector.ps1
#>


#---[Parameters]-----------------------------------------------------------------------------------

Param (
    [String]
    $ScanName = 'EventBased'
)


#---[Imports and preferences]----------------------------------------------------------------------

Import-Module AppLocker

$ErrorActionPreference = 'Stop' # Continue SilentlyContinue Stop 


#---[Variables]------------------------------------------------------------------------------------

$Date = $(Get-Date).ToString("yyyy-MM-dd_HH-mm")

$ScriptPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)

$ComputerName = $env:computername

$Events = [System.String]::Format("{0}\{1}_{2}_{3}_{4}.csv", $ScriptPath, 'Events', $ComputerName, $ScanName, $Date)
$Files = [System.String]::Format("{0}\{1}_{2}_{3}_{4}.txt", $ScriptPath, 'Files', $ComputerName, $ScanName, $Date)
$Inventory = [System.String]::Format("{0}\{1}_{2}_{3}_{4}.csv", $ScriptPath, 'Inventory', $ComputerName, $ScanName, $Date)


#---[Read events]----------------------------------------------------------------------------------

Write-Host "Reading events"

$Query = @"
<QueryList>
  <Query Id="0">
    <Select Path="Microsoft-Windows-AppLocker/EXE and DLL">*[System[Provider[@Name='Microsoft-Windows-AppLocker'] and (EventID=8003 or EventID=8004 or EventID=8006 or EventID=8007)]]</Select>
    <Select Path="Microsoft-Windows-AppLocker/MSI and Script">*[System[Provider[@Name='Microsoft-Windows-AppLocker'] and (EventID=8003 or EventID=8004 or EventID=8006 or EventID=8007)]]</Select>
  </Query>
</QueryList>
"@

$Evts = Get-WinEvent –FilterXml $Query

$SWEvents = New-Object System.IO.StreamWriter ($Events)
$SWEvents.AutoFlush = $True

$Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}"";""{7}"";""{8}"";""{9}"";""{10}""",
"EventID",
"Level",
"TimeCreated",
"Computer",
"PolicyName",
"RuleName",
"FilePath",
"FileHash",
"Fqbn",
"UserID",
"UserName")

$SWEvents.WriteLine($Line)

ForEach ($Evt in $Evts)
{
    $EvtXML = [xml]$Evt.ToXML()

    $EventID = $EvtXML.Event.System.EventID
    $Level = $EvtXML.Event.System.Level
    $TimeCreated = $EvtXML.Event.System.TimeCreated.Attributes.GetNamedItem("SystemTime").Value
    $Computer = $EvtXML.Event.System.Computer
    $PolicyName = $EvtXML.Event.UserData.RuleAndFileData.PolicyName
    $RuleName = $EvtXML.Event.UserData.RuleAndFileData.RuleName
    $FilePath = $EvtXML.Event.UserData.RuleAndFileData.FilePath
    $FileHash = $EvtXML.Event.UserData.RuleAndFileData.FileHash
    $Fqbn = $EvtXML.Event.UserData.RuleAndFileData.Fqbn
    $UserID = $EvtXML.Event.System.Security.Attributes.GetNamedItem("UserID").Value

    $ObjSID = New-Object System.Security.Principal.SecurityIdentifier ($UserID)
    $UserName = $ObjSID.Translate([System.Security.Principal.NTAccount]).Value

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}"";""{7}"";""{8}"";""{9}"";""{10}""",
    "$EventID",
    "$Level",
    "$TimeCreated",
    "$Computer",
    "$PolicyName",
    "$RuleName",
    "$FilePath",
    "$FileHash",
    "$Fqbn",
    "$UserID",
    "$UserName")

    $SWEvents.WriteLine($Line)
}

$SWEvents.Close()

Write-Host "Events read: $($Evts.Count)"

Write-Host ""


#---[List files]----------------------------------------------------------------------------------

Write-Host "Listing files"

$SWFiles = New-Object System.IO.StreamWriter ($Files)
$SWFiles.AutoFlush = $True

$FileCounter = 0
$ErrorCounter = 0

$SREvents = New-Object System.IO.StreamReader ($Events)

While ($RLine = $SREvents.ReadLine())
{
	$Values = $RLine.Split(';')

	$EventID = $Values[0].Substring(1,$Values[0].Length-2)
	$Level = $Values[1].Substring(1,$Values[1].Length-2)
	$TimeCreated = $Values[2].Substring(1,$Values[2].Length-2)
	$Computer = $Values[3].Substring(1,$Values[3].Length-2)
	$PolicyName = $Values[4].Substring(1,$Values[4].Length-2)
	$RuleName = $Values[5].Substring(1,$Values[5].Length-2)
	$FilePath = $Values[6].Substring(1,$Values[6].Length-2)
	$FileHash = $Values[7].Substring(1,$Values[7].Length-2)
	$Fqbn = $Values[8].Substring(1,$Values[8].Length-2)
	$UserID = $Values[9].Substring(1,$Values[9].Length-2)
	$UserName = $Values[10].Substring(1,$Values[10].Length-2)

    $SourceFileName = ""

    If ($FilePath -like "*%WINDIR%*")
    {
        $TestedFileName = $FilePath -Replace "%WINDIR%","C:\Windows"

        If ([System.IO.File]::Exists($TestedFileName))
        {
            $SourceFileName = $TestedFileName
        }
    }
    ElseIf ($FilePath -like "*%SYSTEM32%*")
    {
        $TestedFileName = $FilePath -Replace "%SYSTEM32%","C:\Windows\System32"

        If ([System.IO.File]::Exists($TestedFileName))
        {
            $SourceFileName = $TestedFileName
        }

        $TestedFileName = $FilePath -Replace "%SYSTEM32%","C:\Windows\SysWOW64"

        If ([System.IO.File]::Exists($TestedFileName))
        {
            $SourceFileName = $TestedFileName
        }
    }
    ElseIf ($FilePath -like "*%OSDRIVE%*")
    {
        $TestedFileName = $FilePath -Replace "%OSDRIVE%","C:"

        If ([System.IO.File]::Exists($TestedFileName))
        {
            $SourceFileName = $TestedFileName
        }
    }
    ElseIf ($FilePath -like "*%PROGRAMFILES%*")
    {
        $TestedFileName = $FilePath -Replace "%PROGRAMFILES%","C:\Program Files (x86)"

        If ([System.IO.File]::Exists($TestedFileName))
        {
            $SourceFileName = $TestedFileName
        }

        $TestedFileName = $FilePath -Replace "%PROGRAMFILES%","C:\Program Files"

        If ([System.IO.File]::Exists($TestedFileName))
        {
            $SourceFileName = $TestedFileName
        }
    }
    ElseIf ($FilePath -like "*%REMOVABLE%*")
    {
        Continue
    }
    ElseIf ($FilePath -like "*%HOT%*")
    {
        Continue
    }
    Else
    {
        Continue
    }

    If ($SourceFileName) {
        $FileCounter += 1
        
        $SWFiles.WriteLine($SourceFileName)
    }
    Else
    {
        $ErrorCounter += 1
    }

    If ($FileCounter % 500 -eq 0) {
        Write-Host -NoNewLine "`rFiles found: $FileCounter"
    }
}

$SWFiles.Close()

Write-Host -NoNewLine "`rFiles found: $FileCounter"
Write-Host "`r`nFiles not found: $ErrorCounter"

Write-Host ""


#---[Collect AppLocker file information]----------------------------------------------------------

Write-Host "Collecting AppLocker file information"

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

$SWInventory.WriteLine($Line)

$SRFiles = New-Object System.IO.StreamReader ($Files)

$FileCounter = 0
$ErrorCounter = 0

While ($RLine = $SRFiles.ReadLine())
{
    Try
    {
        $File = Get-Item $RLine

        If ($File.Extension)
        {
            Try
            {
                $AppLockerInfo = Get-AppLockerFileInformation -Path $File.FullName
            }
            Catch
            {
                Continue
            }

            $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}"";""{7}""",
            $File.FullName,
            $File.Extension,
            $File.Length,
            $AppLockerInfo.Path,
            $AppLockerInfo.Publisher,
            $AppLockerInfo.Hash.HashDataString,
            $AppLockerInfo.Hash.SourceFileName,
            $AppLockerInfo.AppX)

            $SWInventory.WriteLine($Line)
        }
    }
    Catch
    {
        $ErrorCounter += 1
    }

    $FileCounter += 1

    If ($FileCounter % 250 -eq 0) {
        Write-Host -NoNewLine "`rFiles info collected: $FileCounter"
    }
}

Write-Host -NoNewLine "`rFiles info collected: $FileCounter"
Write-Host "`nErrors: $ErrorCounter"

$SRFiles.Close()
$SWInventory.Close()

Write-Host ""

Write-Host "Events export done: $Events"
Write-Host "Files list done: $Files"
Write-Host "Inventory done: $Inventory"

Write-Host ""
