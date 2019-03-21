# Example - AppLocker Deployment Scripts

### Environment

```powershell
PS C:\Temp> ls

    Directory: C:\Temp\

Mode                LastWriteTime     Length Name
----                -------------     ------ ----
d----        XX/XX/2019  XX:XX PM            Drafts
d----        XX/XX/2019  XX:XX PM            Inspections
d----        XX/XX/2019  XX:XX PM            Inventories
d----        XX/XX/2019  XX:XX PM            Policies
-a---        XX/XX/2019  XX:XX PM      xxxxx AppLockerDrafter.ps1
-a---        XX/XX/2019  XX:XX PM      xxxxx AppLockerEditor.ps1
-a---        XX/XX/2019  XX:XX PM       xxxx AppLockerInspector.ps1
-a---        XX/XX/2019  XX:XX PM       xxxx AppLockerInventory.ps1
-a---        XX/XX/2019  XX:XX PM       xxxx Setup.ps1

```

### AppLockerInventory.ps1

**Inventory applications (full scan)**

```powershell
PS C:\Temp> .\AppLockerInventory.ps1
Scanning folders
Scanning C:\
Files listed: 93775

Collecting AppLocker information
Files info collected: 79187
Errors: 14588

Files list done: Files_WorstationA_FullScan_2019-XX-XX_XX-XX.txt
Inventory done: Inventory_WorstationA_FullScan_2019-XX-XX_XX-XX.csv

```

**Inventory applications (folder scan)**

```powershell
PS C:\Temp> .\AppLockerInventory.ps1 -FolderToScan 'C:\Program Files\Oracle' -ScanName Oracle
Scanning folders
Scanning C:\Program Files\Oracle
Files listed: 20

Collecting AppLocker information
Files info collected: 20
Errors: 0

Files list done: C:\Temp\Files_WorkstationA_Oracle_2019-XX-XX_XX-XX.txt
Inventory done: C:\Temp\Inventory_WorkstationA_Oracle_2019-XX-XX_XX-XX.csv

```

**Files file**

| Files                                                                                       |
|---------------------------------------------------------------------------------------------|
| C:\Program Files\Oracle\VirtualBox Guest Additions\DIFxAPI.dll                              |
| C:\Program Files\Oracle\VirtualBox Guest Additions\uninst.exe                               |
| C:\Program Files\Oracle\VirtualBox Guest Additions\VBoxControl.exe                          |
| C:\Program Files\Oracle\VirtualBox Guest Additions\VBoxDisp.dll                             |

**Inventory file**

| FullName                                                                                      | Extension | Length  | Path                                                                                        | Publisher                                                                                                                     | Hash                                                               | SourceFileName     | AppX |
|-----------------------------------------------------------------------------------------------|-----------|---------|---------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------|--------------------|------|
| C:\Program Files\Oracle\VirtualBox Guest Additions\DIFxAPI.dll                                | .dll      | 519048  | %PROGRAMFILES%\ORACLE\VIRTUALBOX GUEST   ADDITIONS\DIFXAPI.DLL                              | O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US\DRIVER INSTALL FRAMEWORKS API (DIFXAPI)\DIFXAPI.DLL,2.1.0.0            | 0x1E354677A67AD46B1010522382F4E9BE24ADCA261B2301A91C0B0385997666B9 | DIFxAPI.dll        |      |
| C:\Program Files\Oracle\VirtualBox Guest Additions\uninst.exe                                 | .exe      | 994168  | %PROGRAMFILES%\ORACLE\VIRTUALBOX GUEST ADDITIONS\UNINST.EXE                                 | O=ORACLE CORPORATION, L=REDWOOD SHORES, S=CALIFORNIA, C=US\ORACLE VM VIRTUALBOX GUEST ADDITIONS\,6.0.4.0                      | 0x3978C45D4C2320B757DC6417C6F214895EC46E6AB1D9A23BC49C49FC43BD7842 | uninst.exe         |      |
| C:\Program Files\Oracle\VirtualBox Guest Additions\VBoxControl.exe                            | .exe      | 2507168 | %PROGRAMFILES%\ORACLE\VIRTUALBOX GUEST ADDITIONS\VBOXCONTROL.EXE                            | O=ORACLE CORPORATION, L=REDWOOD SHORES, S=CALIFORNIA, C=US\ORACLE VM VIRTUALBOX GUEST ADDITIONS\VBOXCONTROL.EXE,6.0.4.28413   | 0x1C499EDE427790BAEC2E6C24FCF0E3D2893DC733A57B66105D1FD6D1C1F21E18 | VBoxControl.exe    |      |
| C:\Program Files\Oracle\VirtualBox Guest Additions\VBoxDisp.dll                               | .dll      | 97776   | %PROGRAMFILES%\ORACLE\VIRTUALBOX GUEST ADDITIONS\VBOXDISP.DLL                               | O=ORACLE CORPORATION, L=REDWOOD SHORES, S=CALIFORNIA, C=US\ORACLE VM VIRTUALBOX GUEST ADDITIONS\VBOXDISP.DLL,6.0.4.28413      | 0x5C890CC9ACC55A925D9A30CCCF807EDA4978B9DE20B1681BDFFCCF0F437CE14F | VBoxDisp.dll       |      |

### AppLockerDraft.ps1

**Draft a policy**

```powershell
PS C:\Temp> .\AppLockerDraft.ps1 -InventoriesFolder .\Inventories\Workstations\ -DraftName Workstations
Parsing inventories
Parsing Inventory_WorstationA_FullScan_2019-XX-XX_XX-XX.csv
Lines parsed: 3809
Parsing Inventory_WorstationB_FullScan_2019-XX-XX_XX-XX.csv
Lines parsed: 75948

Drafting policy
Draft done: C:\Temp\Drafts\Draft_Workstations_2019-XX-XX_XX-XX.csv
Executable publisher based rules: 2
Executable hash based rules: 23
Installer publisher based rules: 0
Installer hash based rules: 0
Script publisher based rules: 1
Script hash based rules: 59
Lib publisher based rules: 2
Lib hash based rules: 406
AppX publisher based rules: 0
AppX hash based rules: 0

```

**Draft file**

Examples of publisher based rules:

| RuleType             | AllowedByAdmin | Publisher                                                  |
|----------------------|----------------|------------------------------------------------------------|
| Executable Publisher | Yes            | O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US     |
| Executable Publisher | Yes            | O=ORACLE CORPORATION, L=REDWOOD SHORES, S=CALIFORNIA, C=US |
| Script Publisher     | Yes            | O=MICROSOFT CORPORATION, L=REDMOND,   S=WASHINGTON, C=US   |
| Lib Publisher        | Yes            | O=MICROSOFT CORPORATION, L=REDMOND,   S=WASHINGTON, C=US   |

Examples of hash based rules:

| RuleType        | AllowedByAdmin | SourceFileName               | Hash                                                               | Length  |
|-----------------|----------------|------------------------------|--------------------------------------------------------------------|---------|
| Executable Hash | Yes            | ComSvcConfig.ni.exe          | 0xFFAD6EA271BE7EB881889981C89D3C7CB44AED0C59C330F7C5D9F74D1A9E3A5B | 410112  |
| Executable Hash | Yes            | dfsvc.ni.exe                 | 0xF0F1D7B64737FFE02BD9E2786B4E5B8AC5626F3E107FE96858B5F2C3E3C32FBE | 14336   |
| Executable Hash | Yes            | ehExtHost32.ni.exe           | 0xF99492467025A099B93BE9F5CA846669D953380E96AFD192F1ED2265949C78CF | 254464  |
| Executable Hash | Yes            | MSBuild.ni.exe               | 0xDF721FD028FD1B1801F22B2F878253B59CB30EF8B498DC03EB3DB48F1775D682 | 133632  |

By default, the tag "AllowedByAdmin" is "No". 

### AppLockerEditor.ps1

**Edit a policy**

```powershell
PS C:\Temp> .\AppLockerEditor.ps1 -Drafts .\Drafts\Draft_Workstations_2019-XX-XX_XX-XX_validated.csv -PolicyName Workstations -DllEnforcementMode NotConfigured
Parsing rules files
Parsing C:\Temp\Drafts\Draft_Workstations_2019-XX-XX_XX-XX_validated.csv
Executable publisher based rules: 2
Executable hash based rules: 23
Installer publisher based rules: 0
Installer hash based rules: 0
Script publisher based rules: 1
Script hash based rules: 58
Lib publisher based rules: 2
Lib hash based rules: 391
AppX publisher based rules: 0
AppX hash based rules: 0
Rules not allowed by admin: 16

Publishing policy
Policy done: C:\Temp\Policies\Policy_Workstations_2019-XX-XX_XX-XX.xml

```

**Policy file**

```xml
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="effbe024-9972-46bc-a9c0-19e37157ee78" Name="Signed by O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
    <FilePublisherRule Id="347a7aca-1fec-4ad7-b078-b452089192b7" Name="Signed by O=ORACLE CORPORATION, L=REDWOOD SHORES, S=CALIFORNIA, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePublisherCondition PublisherName="O=ORACLE CORPORATION, L=REDWOOD SHORES, S=CALIFORNIA, C=US" ProductName="*" BinaryName="*">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
    </FilePublisherRule>
	  ...
  </RuleCollection>
  <RuleCollection Type="Msi" EnforcementMode="AuditOnly">
	...
  </RuleCollection>
  <RuleCollection Type="Script" EnforcementMode="AuditOnly">
	...
  </RuleCollection>
  <RuleCollection Type="Dll" EnforcementMode="NotConfigured">
  </RuleCollection>
  <RuleCollection Type="AppX" EnforcementMode="AuditOnly">
	...
  </RuleCollection>
</AppLockerPolicy>
```

### AppLockerInspector.ps1

**Read events and get missing applications**

```powershell
PS C:\Temp> .\AppLockerInspector.ps1
Reading events
Events read: 3194

Listing files
Files found: 3161
Files not found: 30

Collecting AppLocker file information
Files info collected: 3161
Errors: 0

Events export done: C:\Temp\Events_WorkstationA_EventBased_2019-XX-XX_XX-XX.csv
Files list done: C:\Temp\Files_WorkstationA_EventBased_2019-XX-XX_XX-XX.txt
Inventory done: C:\Temp\Inventory_WorkstationA_EventBased_2019-XX-XX_XX-XX.csv

```

**Events file**

| EventID | Level | TimeCreated                    | Computer     | PolicyName | RuleName | FilePath                                    | FileHash                                                         | Fqbn                                                                                                                       | UserID                                         | UserName        |
|---------|-------|--------------------------------|--------------|------------|----------|---------------------------------------------|------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|-----------------|
| 8006    | 3     | 2019-XX-XXTXX:XX:XX.XXXXXXXXXZ | WorkstationA | SCRIPT     | -        | %OSDRIVE%\USERS\USERNAME\DOCUMENTS\TEST.PS1 | D8273C03C4A0B3FB5BC733D25CCB998BB4BBEB19153741DA181F1B888F17B667 | -                                                                                                                          | S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX-XXXX | Domain\Username |
| 8003    | 3     | 2019-XX-XXTXX:XX:XX.XXXXXXXXXZ | WorkstationA | EXE        | -        | %SYSTEM32%\DLLHOST.EXE                      | 9A00E2E4B3D514C7D29B66243F31F9DC9AB22BDF86935FACD8716821A9CE056D | O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US\MICROSOFTÂ®   WINDOWSÂ® OPERATING SYSTEM\DLLHOST.EXE\6.1.7600.16385 | S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX-XXXX | Domain\Username |
| 8003    | 3     | 2019-XX-XXTXX:XX:XX.XXXXXXXXXZ | WorkstationA | EXE        | -        | %SYSTEM32%\MMC.EXE                          | 809032BA5C63F7FC52F5B56B6148EF2EC22D2F90C0D1D6FFC2DE49012DDEBA6A | O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US\MICROSOFTÂ®   WINDOWSÂ® OPERATING SYSTEM\MMC.EXE\6.1.7600.16385     | S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX-XXXX | Domain\Username |
| 8003    | 3     | 2019-XX-XXTXX:XX:XX.XXXXXXXXXZ | WorkstationA | EXE        | -        | %SYSTEM32%\MMC.EXE                          | 809032BA5C63F7FC52F5B56B6148EF2EC22D2F90C0D1D6FFC2DE49012DDEBA6A | O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US\MICROSOFTÂ®   WINDOWSÂ® OPERATING SYSTEM\MMC.EXE\6.1.7600.16385     | S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX-XXXX | Domain\Username |



