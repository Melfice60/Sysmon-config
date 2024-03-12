$VersionPattern = "v?(\d{2}\.\d{1,2})"
$TempFolder = "$env:TEMP\Sysmon"
$LogFile = "$env:TEMP\SysmonUpdate.log"
$config_file = "" #A modifier en fonction des besoins
$check_exist = Get-Service -Name Sysmon*


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


Function Retrieve-Config{
	Invoke-WebRequest -Uri https://raw.githubusercontent.com/melfice60/sysmon-config/master/$config_file -Outfile sysmonconfig-export.xml
}


Function Install-Sysmon{
    ""
    & $TempFolder\Sysmon64.exe -i sysmonconfig-export.xml -accepteula
    ""
}

Get-Date | Tee-Object -FilePath $LogFile -Append

if(-not $check_exist){
   New-TempEnvironment | Tee-Object -FilePath $LogFile -Append
   Download-SysmonZip | Tee-Object -FilePath $LogFile -Append
   Unzip-File | Tee-Object -FilePath $LogFile -Append
   Retrieve-Config | Tee-Object -FilePath $LogFile -Append
   Install-Sysmon | Tee-Object -FilePath $LogFile -Append
   Remove-TempEnvironment | Tee-Object -FilePath $LogFile -Append
} else {
    "Sysmon already exist." | Tee-Object -FilePath $LogFile -Append
}

