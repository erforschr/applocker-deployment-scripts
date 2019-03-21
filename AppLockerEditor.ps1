#requires -version 2

<#
.SYNOPSIS
    AppLocker Editor

.DESCRIPTION
    Create an XML AppLocker policy from drafts.

.PARAMETER Drafts
    List of drafts files.

.PARAMETER PolicyName
    Tag on the ouput file name.
	
.PARAMETER ExeEnforcementMode
	Enforcement mode for exe rules.

.PARAMETER MsiEnforcementMode
	Enforcement mode for msi rules.

.PARAMETER ScriptEnforcementMode
	Enforcement mode for script rules.

.PARAMETER DllEnforcementMode
	Enforcement mode for dll rules.

.PARAMETER AppXEnforcementMode
	Enforcement mode for appx rules.

.OUTPUTS
    Policy: XML AppLocker policy.

.NOTES
    Version: 0.1
    Author: Erforschr
    License: MIT License
    Creation Date: 01/08/2019
  
.EXAMPLE
    .\AppLockerEditor.ps1 -Drafts .\Drafts\Draft_Workstations_2019-XX-XX_XX-XX.csv -PolicyName Workstations
	
.EXAMPLE
    .\AppLockerEditor.ps1 -Drafts .\Drafts\Draft_Servers_2019-XX-XX_XX-XX.csv -PolicyName Servers
#>


#---[Parameters]-----------------------------------------------------------------------------------

Param (
    [Parameter(Mandatory=$True)]
    [ValidateScript({
        ForEach ($File in $_)
        {
            $FileObj = Get-Item $File

            If(-Not ($FileObj.FullName | Test-Path -PathType 'Leaf'))
            {
                throw "File not found"
            }
            If (-Not ($FileObj.FullName -Like '*.csv'))
            {
                throw "File is not a .csv file"
            }
        }

        return $true
    })]
    [System.IO.FileInfo[]]
    $Drafts
    ,
    [String]
    $PolicyName = 'Policy'
    ,
    [String]
    $ExeEnforcementMode="AuditOnly"
    ,
    [String]
    $MsiEnforcementMode="AuditOnly"
    ,
    [String]
    $ScriptEnforcementMode="AuditOnly"
    ,
    [String]
    $DllEnforcementMode="AuditOnly"
    ,
    [String]
    $AppXEnforcementMode="AuditOnly"
)


#---[Imports and preferences]----------------------------------------------------------------------

$ErrorActionPreference = 'Stop' # Continue SilentlyContinue Stop 


#---[Variables]------------------------------------------------------------------------------------

$Date = $(Get-Date).ToString("yyyy-MM-dd_HH-mm")

$ScriptPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)

$Policy = [System.String]::Format("{0}\{1}\{2}_{3}_{4}.xml", $ScriptPath, 'Policies', 'Policy', $PolicyName, $Date)


#---[Functions]------------------------------------------------------------------------------------

Function GetPolicyHeader
{
Param (
)

$Content = @"
<AppLockerPolicy Version="1">

"@

Return $Content
}

Function GetPolicyFooter
{
Param (
)

$Content = @"
</AppLockerPolicy>

"@

Return $Content
}

Function GetRuleCollectionHeader
{
Param (
    [Parameter(Mandatory=$True)][String]$Type,
    [Parameter(Mandatory=$True)][String]$EnforcementMode
)

$Content = [System.String]::Format(@"
  <RuleCollection Type="{0}" EnforcementMode="{1}">

"@,
$Type,$EnforcementMode)

Return $Content
}

Function GetRuleCollectionFooter
{
Param (
)

$Content = @"
  </RuleCollection>

"@

Return $Content
}

Function GetFilePublisherRule
{
Param (
    [Parameter(Mandatory=$True)][String]$Publisher
)

$ID = [GUID]::NewGuid()

$Content = [System.String]::Format(@"
    <FilePublisherRule Id="{0}" Name="Signed by {1}" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="{1}" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>

"@,$ID,$Publisher)

Return $Content
}


Function GetFileHashRule
{
Param (
    [Parameter(Mandatory=$True)][String]$SourceFileName,
    [Parameter(Mandatory=$True)][String]$Hash,
    [Parameter(Mandatory=$True)][String]$Length
)

$ID = [GUID]::NewGuid()

$Content = [System.String]::Format(@"
    <FileHashRule Id="{0}" Name="Program Files: {1}" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FileHashCondition>
          <FileHash Type="SHA256" Data="{2}" SourceFileName="{1}" SourceFileLength="{3}" />
        </FileHashCondition>
      </Conditions>
    </FileHashRule>

"@,$ID, $SourceFileName, $Hash, $Length)

Return $Content
}


#---[Parse rules file]-----------------------------------------------------------------------------

Write-Host "Parsing rules files"

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


ForEach ($Draft in $Drafts)
{
    $DraftFileObj = Get-Item $Draft
    
    Write-Host "Parsing $DraftFileObj"
    
    $SRDraft = New-Object System.IO.StreamReader ($DraftFileObj)
    
    # Counters
    $NotAllowedCounter = 0

    While ($RLine = $SRDraft.ReadLine())
    {
        $Values = $RLine.Split(';')

        $RuleType = $Values[0]
        $AllowedByAdmin = $Values[1]
        $Publisher = $Values[2]
        $SourceFileName = $Values[3]
        $Path = $Values[4]
        $Hash = $Values[5]
        $Length = $Values[6]

        If ($AllowedByAdmin -Like 'Yes')
        {
            If ($RuleType -eq "Executable Publisher")
            {
                $Rule = [System.String]::Format("{0}",$Publisher)
                If (-not ($HSExePublisher -contains $Rule))
                {
                    $t = $HSExePublisher.Add($Rule)
                }
            }
            ElseIf ($RuleType -eq "Executable Hash")
            {
                $Rule = [System.String]::Format("{0};{1};{2}",$SourceFileName,$Hash,$Length)
                If (-not ($HSExeHash -contains $Rule))
                {
                    $t = $HSExeHash.Add($Rule)
                }
            }
            ElseIf ($RuleType -eq "Installer Publisher")
            {
                $Rule = [System.String]::Format("{0}",$Publisher)
                If (-not ($HSInstPublisher -contains $Rule))
                {
                    $t = $HSInstPublisher.Add($Rule)
                }
            }
            ElseIf ($RuleType -eq "Installer Hash")
            {
                $Rule = [System.String]::Format("{0};{1};{2}",$SourceFileName,$Hash,$Length)
                If (-not ($HSInstHash -contains $Rule))
                {
                    $t = $HSInstHash.Add($Rule)
                }
            }
            ElseIf ($RuleType -eq "Script Publisher")
            {
                $Rule = [System.String]::Format("{0}",$Publisher)
                If (-not ($HSScriptPublisher -contains $Rule))
                {
                    $t = $HSScriptPublisher.Add($Rule)
                }
            }
            ElseIf ($RuleType -eq "Script Hash")
            {
                $Rule = [System.String]::Format("{0};{1};{2}",$SourceFileName,$Hash,$Length)
                If (-not ($HSScriptHash -contains $Rule))
                {
                    $t = $HSScriptHash.Add($Rule)
                }
            }
            ElseIf ($RuleType -eq "Lib Publisher")
            {
                $Rule = [System.String]::Format("{0}",$Publisher)
                If (-not ($HSLibPublisher -contains $Rule))
                {
                    $t = $HSLibPublisher.Add($Rule)
                }
            }
            ElseIf ($RuleType -eq "Lib Hash")
            {
                $Rule = [System.String]::Format("{0};{1};{2}",$SourceFileName,$Hash,$Length)
                If (-not ($HSLibHash -contains $Rule))
                {
                    $t = $HSLibHash.Add($Rule)
                }
            }
            ElseIf ($RuleType -eq "AppX Publisher")
            {
                $Rule = [System.String]::Format("{0}",$Publisher)
                If (-not ($HSAppXPublisher -contains $Rule))
                {
                    $t = $HSAppXPublisher.Add($Rule)
                }
            }
            ElseIf ($RuleType -eq "AppX Hash")
            {
                $Rule = [System.String]::Format("{0};{1};{2}",$SourceFileName,$Hash,$Length)
                If (-not ($HSAppXHash -contains $Rule))
                {
                    $t = $HSAppXHash.Add($Rule)
                }
            }
        }
        Else
        {
            $NotAllowedCounter += 1
        }
    }
    
    Write-Host "Executable publisher based rules: $($HSExePublisher.count)"
    Write-Host "Executable hash based rules: $($HSExeHash.count)"
    Write-Host "Installer publisher based rules: $($HSInstPublisher.count)"
    Write-Host "Installer hash based rules: $($HSInstHash.count)"
    Write-Host "Script publisher based rules: $($HSScriptPublisher.count)"
    Write-Host "Script hash based rules: $($HSScriptHash.count)"
    Write-Host "Lib publisher based rules: $($HSLibPublisher.count)"
    Write-Host "Lib hash based rules: $($HSLibHash.count)"
    Write-Host "AppX publisher based rules: $($HSAppXPublisher.count)"
    Write-Host "AppX hash based rules: $($HSAppXHash.count)"
    Write-Host "Rules not allowed by admin: $NotAllowedCounter"
    
    $SRDraft.Close()
}

Write-Host ""


#---[Publish policy]-------------------------------------------------------------------------------

Write-Host "Publishing policy"

$SWPolicy = New-Object System.IO.StreamWriter ($Policy)
$SWPolicy.AutoFlush = $True


$Content = GetPolicyHeader
$SWPolicy.Write($Content)

# Executable
$Content = GetRuleCollectionHeader "Exe" $ExeEnforcementMode
$SWPolicy.Write($Content)

ForEach ($Rule in $HSExePublisher)
{
    $Publisher = $Rule

    $Content = GetFilePublisherRule $Publisher
    $SWPolicy.Write($Content)
}

ForEach ($Rule in $HSExeHash)
{
    $SourceFileName = $Rule.Split(';')[0]
    $Hash = $Rule.Split(';')[1]
    $Length = $Rule.Split(';')[2]

    $Content = GetFileHashRule $SourceFileName $Hash $Length
    $SWPolicy.Write($Content)
}

$Content = GetRuleCollectionFooter
$SWPolicy.Write($Content)

# Installer
$Content = GetRuleCollectionHeader "Msi" $MsiEnforcementMode
$SWPolicy.Write($Content)

ForEach ($Rule in $HSInstPublisher)
{
    $Publisher = $Rule

    $Content = GetFilePublisherRule $Publisher
    $SWPolicy.Write($Content)
}

ForEach ($Rule in $HSInstHash)
{
    $SourceFileName = $Rule.Split(';')[0]
    $Hash = $Rule.Split(';')[1]
    $Length = $Rule.Split(';')[2]

    $Content = GetFileHashRule $SourceFileName $Hash $Length
    $SWPolicy.Write($Content)
}

$Content = GetRuleCollectionFooter
$SWPolicy.Write($Content)

# Script
$Content = GetRuleCollectionHeader "Script" $ScriptEnforcementMode
$SWPolicy.Write($Content)

ForEach ($Rule in $HSScriptPublisher)
{
    $Publisher = $Rule

    $Content = GetFilePublisherRule $Publisher
    $SWPolicy.Write($Content)
}

ForEach ($Rule in $HSScriptHash)
{
    $SourceFileName = $Rule.Split(';')[0]
    $Hash = $Rule.Split(';')[1]
    $Length = $Rule.Split(';')[2]

    $Content = GetFileHashRule $SourceFileName $Hash $Length
    $SWPolicy.Write($Content)
}

$Content = GetRuleCollectionFooter
$SWPolicy.Write($Content)

# Lib
$Content = GetRuleCollectionHeader "Dll" $DllEnforcementMode
$SWPolicy.Write($Content)

ForEach ($Rule in $HSLibPublisher)
{
    $Publisher = $Rule

    $Content = GetFilePublisherRule $Publisher
    $SWPolicy.Write($Content)
}

ForEach ($Rule in $HSLibHash)
{
    $SourceFileName = $Rule.Split(';')[0]
    $Hash = $Rule.Split(';')[1]
    $Length = $Rule.Split(';')[2]

    $Content = GetFileHashRule $SourceFileName $Hash $Length
    $SWPolicy.Write($Content)
}

$Content = GetRuleCollectionFooter
$SWPolicy.Write($Content)

# AppX
$Content = GetRuleCollectionHeader "AppX" $AppXEnforcementMode
$SWPolicy.Write($Content)

ForEach ($Rule in $HSAppXPublisher)
{
    $Publisher = $Rule

    $Content = GetFilePublisherRule $Publisher
    $SWPolicy.Write($Content)
}

ForEach ($Rule in $HSAppXHash)
{
    $SourceFileName = $Rule.Split(';')[0]
    $Hash = $Rule.Split(';')[1]
    $Length = $Rule.Split(';')[2]

    $Content = GetFileHashRule $SourceFileName $Hash $Length
    $SWPolicy.Write($Content)
}

$Content = GetRuleCollectionFooter
$SWPolicy.Write($Content)

$Content = GetPolicyFooter
$SWPolicy.Write($Content)

$SWPolicy.Close()

Write-Host "Policy done: $Policy"

Write-Host ""
