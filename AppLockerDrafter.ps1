#requires -version 2

<#
.SYNOPSIS
    AppLocker Drafter

.DESCRIPTION
    Creates a list of publisher based and hash based rules from an inventories list.

.PARAMETER InventoriesFolder
    Inventories folder.

.PARAMETER DraftName
    Tag on the ouput file name.

.OUTPUTS
    Draft: List of rules.

.NOTES
    Version: 0.1
    Author: Erforschr
    License: MIT License
    Creation Date: 01/08/2019
  
.EXAMPLE
    .\AppLockerDrafter.ps1
	
.EXAMPLE
    .\AppLockerDrafter.ps1 -DraftName Workstations -InventoriesFolder .\Inventories\Workstations
	
.EXAMPLE
    .\AppLockerDrafter.ps1 -DraftName Servers -InventoriesFolder .\Inventories\Servers
#>


#---[Parameters]-----------------------------------------------------------------------------------

Param (
    [ValidateScript({
        $FileObj = Get-Item $_
        
        If(-Not ($FileObj.FullName | Test-Path -PathType 'Container'))
        {
            throw "Path is not a valid path"
        }
    
        return $true
    })]
    [System.IO.FileInfo]
    $InventoriesFolder = 'Inventories'
    ,
    [String]
    $DraftName = 'Draft'
)


#---[Imports and preferences]----------------------------------------------------------------------

$ErrorActionPreference = 'Stop' # Continue SilentlyContinue Stop 


#---[Variables]------------------------------------------------------------------------------------

$Date = $(Get-Date).ToString("yyyy-MM-dd_HH-mm")

$ScriptPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)

$Draft = [System.String]::Format("{0}\{1}\{2}_{3}_{4}.csv", $ScriptPath, 'Drafts', 'Draft', $DraftName, $Date)

$AllowedByAdminDefaultValue = 'No'


#---[Parse inventories]----------------------------------------------------------------------------

Write-Host "Parsing inventories"

# HashSet for files aggreagation
$HSExePublisher = New-Object System.Collections.Generic.HashSet[string]
$HSExeHash = New-Object System.Collections.Generic.HashSet[string]

$HSInstPublisher = New-Object System.Collections.Generic.HashSet[string]
$HSInstHash = New-Object System.Collections.Generic.HashSet[string]

$HSScriptPublisher = New-Object System.Collections.Generic.HashSet[string]
$HSScriptHash = New-Object System.Collections.Generic.HashSet[string]

$HSLibPublisher = New-Object System.Collections.Generic.HashSet[string]
$HSLibHash = New-Object System.Collections.Generic.HashSet[string]

$HSAppXPublisher = New-Object System.Collections.Generic.HashSet[string]
$HSAppXHash = New-Object System.Collections.Generic.HashSet[string]


Get-ChildItem $InventoriesFolder | ForEach-Object {

    If ($($_.FullName).EndsWith(".csv"))
    {
        Write-Host "Parsing $_"

        $SRInventory = New-Object System.IO.StreamReader ($_.FullName)

        $LineCounter = 0


        While ($RLine = $SRInventory.ReadLine())
        {
            $Values = $RLine.Split(';')

            $FullName = $Values[0].Substring(1,$Values[0].Length-2)
            $Extension = $Values[1].Substring(1,$Values[1].Length-2)
            $Length = $Values[2].Substring(1,$Values[2].Length-2)
            $Path = $Values[3].Substring(1,$Values[3].Length-2)
            $Publisher = $Values[4].Substring(1,$Values[4].Length-2)
            $Hash = $Values[5].Substring(1,$Values[5].Length-2)
            $SourceFileName = $Values[6].Substring(1,$Values[6].Length-2)
            $AppX = $Values[7].Substring(1,$Values[7].Length-2)


            If (@('.exe', '.com') -contains $Extension)
            {
                If ($Publisher) 
                {
                    $Rule = $Publisher.Split('\')[0]
                    If (-not ($HSExePublisher -contains $Rule))
                    {
                        $t = $HSExePublisher.Add($Rule)
                    }
                }
                ElseIf ($Hash)
                {
                    $Rule = [System.String]::Format("{0};{1};{2};{3}",$SourceFileName,$Path,$Hash,$Length)
                    If (-not ($HSExeHash -contains $Rule))
                    {
                        $t = $HSExeHash.Add($Rule)
                    }
                }
            }
            ElseIf (@('.msi', '.mst') -contains $Extension)
            {
                If ($Publisher) 
                {
                    $Rule = $Publisher.Split('\')[0]
                    If (-not ($HSInstPublisher -contains $Rule))
                    {
                        $t = $HSInstPublisher.Add($Rule)
                    }
                }
                ElseIf ($Hash)
                {
                    $Rule = [System.String]::Format("{0};{1};{2};{3}",$SourceFileName,$Path,$Hash,$Length)
                    If (-not ($HSInstHash -contains $Rule))
                    {
                        $t = $HSInstHash.Add($Rule)
                    }
                }
            }
            ElseIf (@('.ps1', '.bat', '.cmd', '.vbs', '.js') -contains $Extension)
            {
                If ($Publisher) 
                {
                    $Rule = $Publisher.Split('\')[0]
                    If (-not ($HSScriptPublisher -contains $Rule))
                    {
                        $t = $HSScriptPublisher.Add($Rule)
                    }
                }
                ElseIf ($Hash)
                {
                    $Rule = [System.String]::Format("{0};{1};{2};{3}",$SourceFileName,$Path,$Hash,$Length)
                    If (-not ($HSScriptHash -contains $Rule))
                    {
                        $t = $HSScriptHash.Add($Rule)
                    }
                }
            }
            ElseIf (@('.dll', '.ocx') -contains $Extension)
            {
                If ($Publisher) 
                {
                    $Rule = $Publisher.Split('\')[0]
                    If (-not ($HSLibPublisher -contains $Rule))
                    {
                        $t = $HSLibPublisher.Add($Rule)
                    }
                }
                ElseIf ($Hash)
                {
                    $Rule = [System.String]::Format("{0};{1};{2};{3}",$SourceFileName,$Path,$Hash,$Length)
                    If (-not ($HSLibHash -contains $Rule))
                    {
                        $t = $HSLibHash.Add($Rule)
                    }
                }
            }
            ElseIf (@('.appx') -contains $Extension)
            {
                If ($Publisher) 
                {
                    $Rule = $Publisher.Split('\')[0]
                    If (-not ($HSAppXPublisher -contains $Rule))
                    {
                        $t = $HSAppXPublisher.Add($Rule)
                    }
                }
                ElseIf ($Hash)
                {
                    $Rule = [System.String]::Format("{0};{1};{2};{3}",$SourceFileName,$Path,$Hash,$Length)
                    If (-not ($HSAppXHash -contains $Rule))
                    {
                        $t = $HSAppXHash.Add($Rule)
                    }
                }
            }

            $LineCounter += 1

            If ($LineCounter % 10000 -eq 0)
            {
                Write-Host -NoNewLine "`rLines parsed: $LineCounter"
            }
        }
        
        Write-Host -NoNewLine "`rLines parsed: $LineCounter"
		Write-Host -NoNewLine "`r`n"
        
        $SRInventory.Close()
    }
}

Write-Host ""


#---[Draft policy]-----------------------------------------------------------------------------

Write-Host "Drafting policy"

# File header
$SWDraft = New-Object System.IO.StreamWriter ($Draft)
$SWDraft.AutoFlush = $True

$Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
"RuleType",
"AllowedByAdmin",
"Publisher",
"SourceFileName",
"Path",
"Hash",
"Length")

$SWDraft.WriteLine($Line)

# Counters
$ExePubCounter = 0
$ExeHashCounter = 0
$InstPubCounter = 0
$InstHashCounter = 0
$ScriptPubCounter = 0
$ScriptHashCounter = 0
$LibPubCounter = 0
$LibHashCounter = 0
$AppXPubCounter = 0
$AppXHashCounter = 0

# Executable rules
ForEach ($PublisherID in $HSExePublisher)
{
    $Publisher = $PublisherID

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "Executable Publisher",
    "$AllowedByAdminDefaultValue",
    "$Publisher",
    "",
    "",
    "",
    "")

    $SWDraft.WriteLine($Line)
    
    $ExePubCounter += 1
}

ForEach ($HashID in $HSExeHash)
{
    $SourceFileName = $HashID.Split(';')[0]
    $Path = $HashID.Split(';')[1]
    $Hash = $HashID.Split(';')[2]
    $Length = $HashID.Split(';')[3]

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "Executable Hash",
    "$AllowedByAdminDefaultValue",
    "",
    "$SourceFileName",
    "$Path",
    "$Hash",
    "$Length")

    $SWDraft.WriteLine($Line)
    
    $ExeHashCounter += 1
}

# Installer rules
ForEach ($PublisherID in $HSInstPublisher)
{
    $Publisher = $PublisherID

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "Installer Publisher",
    "$AllowedByAdminDefaultValue",
    "$Publisher",
    "",
    "",
    "",
    "")

    $SWDraft.WriteLine($Line)
    
    $InstPubCounter += 1
}

ForEach ($HashID in $HSInstHash)
{
    $SourceFileName = $HashID.Split(';')[0]
    $Path = $HashID.Split(';')[1]
    $Hash = $HashID.Split(';')[2]
    $Length = $HashID.Split(';')[3]

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "Installer Hash",
    "$AllowedByAdminDefaultValue",
    "",
    "$SourceFileName",
    "$Path",
    "$Hash",
    "$Length")

    $SWDraft.WriteLine($Line)
    
    $InstHashCounter += 1
}

# Script rules
ForEach ($PublisherID in $HSScriptPublisher)
{
    $Publisher = $PublisherID

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "Script Publisher",
    "$AllowedByAdminDefaultValue",
    "$Publisher",
    "",
    "",
    "",
    "")

    $SWDraft.WriteLine($Line)
    
    $ScriptPubCounter += 1
}

ForEach ($HashID in $HSScriptHash)
{
    $SourceFileName = $HashID.Split(';')[0]
    $Path = $HashID.Split(';')[1]
    $Hash = $HashID.Split(';')[2]
    $Length = $HashID.Split(';')[3]

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "Script Hash",
    "$AllowedByAdminDefaultValue",
    "",
    "$SourceFileName",
    "$Path",
    "$Hash",
    "$Length")

    $SWDraft.WriteLine($Line)
    
    $ScriptHashCounter += 1
}

# Lib rules
ForEach ($PublisherID in $HSLibPublisher)
{
    $Publisher = $PublisherID

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "Lib Publisher",
    "$AllowedByAdminDefaultValue",
    "$Publisher",
    "",
    "",
    "",
    "")

    $SWDraft.WriteLine($Line)
    
    $LibPubCounter += 1
}

ForEach ($HashID in $HSLibHash)
{
    $SourceFileName = $HashID.Split(';')[0]
    $Path = $HashID.Split(';')[1]
    $Hash = $HashID.Split(';')[2]
    $Length = $HashID.Split(';')[3]

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "Lib Hash",
    "$AllowedByAdminDefaultValue",
    "",
    "$SourceFileName",
    "$Path",
    "$Hash",
    "$Length")

    $SWDraft.WriteLine($Line)
    
    $LibHashCounter += 1
}

# AppX rules
ForEach ($PublisherID in $HSAppXPublisher)
{
    $Publisher = $PublisherID

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "AppX Publisher",
    "$AllowedByAdminDefaultValue",
    "$Publisher",
    "",
    "",
    "",
    "")

    $SWDraft.WriteLine($Line)
    
    $AppXPubCounter += 1
}

ForEach ($HashID in $HSAppXHash)
{
    $SourceFileName = $HashID.Split(';')[0]
    $Path = $HashID.Split(';')[1]
    $Hash = $HashID.Split(';')[2]
    $Length = $HashID.Split(';')[3]

    $Line = [System.String]::Format("""{0}"";""{1}"";""{2}"";""{3}"";""{4}"";""{5}"";""{6}""",
    "AppX Hash",
    "$AllowedByAdminDefaultValue",
    "",
    "$SourceFileName",
    "$Path",
    "$Hash",
    "$Length")

    $SWDraft.WriteLine($Line)
    
    $AppXHashCounter += 1
}

$SWDraft.Close()

Write-Host "Draft done: $Draft"

Write-Host "Executable publisher based rules: $ExePubCounter"
Write-Host "Executable hash based rules: $ExeHashCounter"
Write-Host "Installer publisher based rules: $InstPubCounter"
Write-Host "Installer hash based rules: $InstHashCounter"
Write-Host "Script publisher based rules: $ScriptPubCounter"
Write-Host "Script hash based rules: $ScriptHashCounter"
Write-Host "Lib publisher based rules: $LibPubCounter"
Write-Host "Lib hash based rules: $LibHashCounter"
Write-Host "AppX publisher based rules: $AppXPubCounter"
Write-Host "AppX hash based rules: $AppXHashCounter"

Write-Host ""
