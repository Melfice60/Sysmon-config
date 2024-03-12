$VersionPattern = "v?(\d{2}\.\d{1,2})"
$TempFolder = "$env:TEMP\Sysmon"
$LogFile = "$env:TEMP\SysmonUpdate.log"
$config_file = "sysmon_config_high.xml"

Function Get-SysmonLocation{
    return Get-ChildItem $env:SystemRoot -Filter Sysmon64.exe -ErrorAction SilentlyContinue | Select -First 1
}

Function Get-SysmonInstalledVersion{
    $exe = Get-SysmonLocation
    if($exe){
        return $exe.VersionInfo.ProductVersion
    }
    return $false
}

Function Get-SysmonCurrentVersion{
    #$viaCMD = & cmd /c curl "https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon" | findstr h1
    #$Uri = "https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon" #h1 - request is tarpitted
    $Uri = "https://community.chocolatey.org/packages/sysmon" #title
    $Request = Invoke-WebRequest $Uri -UseBasicParsing
    if($Request){
        $Document = New-Object -Com 'HTMLFile'
        $Document.IHTMLDocument2_Write($Request.RawContent)
        $h1 = $Document.getElementsByTagName("title")
        if($h1){
            $CurrentVersionText = $h1[0].innerText
            if($CurrentVersionText -match $VersionPattern){
                $CurrentVersion = $Matches[1]
                return $CurrentVersion
            }
        }
    }
    return $false
}

Function New-TempEnvironment{
    if(-not (Test-Path $TempFolder)){
        mkdir $TempFolder
        "Created $TempFolder"
    }
}

function Remove-TempEnvironment{
    Get-ChildItem $TempFolder -Recurse | Remove-Item -Force
    Remove-Item $TempFolder
    "Removed $TempFolder and contents"
}

Function Download-SysmonZip{
    $URI = "https://download.sysinternals.com/files/Sysmon.zip"
    $Request = Invoke-WebRequest $Uri -OutFile $TempFolder\Sysmon.zip
    "Downloaded Sysmon.zip"
}

Function Unzip-File{
    Expand-Archive "$TempFolder\Sysmon.zip" -DestinationPath $TempFolder -Force -Verbose
    "Extracted Sysmon.zip to $TempFolder"
}

Function Uninstall-Sysmon{
    $Installed = Get-SysmonLocation
    if($Installed){
        ""
        & sysmon64 -u
        $Installed | Remove-Item
        ""
        "Uninstalled $($Installed.FullName)"
    } else {
        return "Not installed"
    }    
}

Function Install-Sysmon{
    ""
    & $TempFolder\Sysmon64.exe -i sysmonconfig-export.xml -accepteula
    ""
}

Function Retrieve-Config{
	Invoke-WebRequest -Uri https://raw.githubusercontent.com/melfice60/sysmon-config/master/$config-file -Outfile sysmonconfig-export.xml
}

$InstalledVersion = Get-SysmonInstalledVersion
$CurrentVersion = Get-SysmonCurrentVersion
Get-Date | Tee-Object -FilePath $LogFile -Append
"Installed: $InstalledVersion" | Tee-Object -FilePath $LogFile -Append
"Current: $CurrentVersion" | Tee-Object -FilePath $LogFile -Append
if($CurrentVersion -and $InstalledVersion -ne $CurrentVersion){
   "Installing version: $CurrentVersion" | Tee-Object -FilePath $LogFile -Append
   
   Uninstall-Sysmon | Tee-Object -FilePath $LogFile -Append
   New-TempEnvironment | Tee-Object -FilePath $LogFile -Append
   Download-SysmonZip | Tee-Object -FilePath $LogFile -Append
   Unzip-File | Tee-Object -FilePath $LogFile -Append
   Install-Sysmon | Tee-Object -FilePath $LogFile -Append
   Remove-TempEnvironment | Tee-Object -FilePath $LogFile -Append
} else {
    "No update will occur." | Tee-Object -FilePath $LogFile -Append
}

