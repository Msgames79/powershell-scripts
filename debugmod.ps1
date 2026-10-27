# source: https://github.com/constup/vdf-converter-powershell/blob/master/src%2Fvdf-converter.ps1
#Licensed under MPL 2.0
#https://www.mozilla.org/en-US/MPL/2.0/
function ConvertFrom-Vdf {
    param (
        [Parameter(Mandatory = $true)]
        [string]$vdfContent
    )

    $lines = $vdfContent -split "`r?`n"
    $keysBuffer = [System.Collections.Generic.List[string]]::new()
    $valuesBuffer = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()

        if ($trimmedLine -eq "{") {
            if ($currentPSObject) {
                $valuesBuffer.Add($currentPSObject)
                $currentPSObject = [PSCustomObject]@{}
            }
            else {
                $currentPSObject = [PSCustomObject]@{}
            }
        }
        elseif ($trimmedLine -eq "}") {
            if ($keysBuffer.Count -gt 0) {
                $key = $keysBuffer[$keysBuffer.Count - 1]
                $keysBuffer.RemoveAt($keysBuffer.Count - 1)
            }

            if ($valuesBuffer.Count -gt 0) {
                $parentObject = $valuesBuffer[$valuesBuffer.Count - 1]
                $valuesBuffer.RemoveAt($valuesBuffer.Count - 1)
            }
            else {
                $parentObject = [PSCustomObject]@{}
            }

            if ($null -eq $parentObject) {
                $parentObject = [PSCustomObject]@{}
            }
            $parentObject | Add-Member -MemberType NoteProperty -Name $key -Value $currentPSObject
            $currentPSObject = $parentObject
        }
        else {
            $stringMatches = [regex]::Matches($trimmedLine, '"([^"]*)"')
            if ($stringMatches.Count -eq 1) {
                $trimmedLine = $trimmedLine.Trim("`"")
                $keysBuffer.Add($trimmedLine)
            }
            elseif ($stringMatches.Count -eq 2) {
                $currentPSObject | Add-Member -MemberType NoteProperty -Name $stringMatches[0].Groups[1].Value -Value $stringMatches[1].Groups[1].Value
            }
        }
    }

    return $currentPSObject
}

if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
    "Only for Windows"
    exit
}
Set-Location $PSScriptRoot
[xml]$csProj = Get-ChildItem ".\*.csproj" | Get-Content -Raw
$pluginName = $csProj.Project.PropertyGroup.AssemblyName
$appId = "477160"
$gameFolderName = "Human Fall Flat"
$ProcessName = "Human"

if (-not (Test-Path "HKCU:\Software\Valve\Steam")) {
    Write-Output "Steam is not installed"
    Read-Host
}

$flag = $true
$steamPath = "$((Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath)\steamapps"
$vdfPSObject = ConvertFrom-Vdf -vdfContent (Get-Content -Path "${steamPath}\libraryfolders.vdf" -Raw)
for ($i = 0; $i -lt ($vdfPSObject.libraryfolders | Get-Member -membertype noteproperty).Count; $i++) {
    if ($vdfPSObject.libraryfolders."$i".apps.psobject.Properties["${appId}"]) {
        $gameFolder = "$([Regex]::Replace(($vdfPSObject.libraryfolders."$i".path), "\\\\", "\").ToString())steamapps\common\${gameFolderName}"
        $flag = $false
        break
    }
}
if ($flag) {
    Write-Output "${gameFolderName} is not installed"
    Read-Host
}


dotnet build
if ($?) {
    dotnet build -c Release
    $ErrorActionPreference = 'Continue'
    if (Get-ItemPropertyValue "HKCU:\Software\Valve\Steam\Apps\${appId}" "Running") {
        "Waiting ${gameFolderName} to Close"
        Stop-Process -Name "${ProcessName}"<#, "dnSpy"#> -ErrorAction SilentlyContinue
        while (Get-ItemPropertyValue "HKCU:\Software\Valve\Steam\Apps\${appId}" "Running") {
            Start-Sleep -Seconds 1
        }
    }
    do {
        Remove-Item "${gameFolder}\BepInEx\plugins\${pluginName}\${pluginName}.dll" -Force
    } while (Test-Path "${gameFolder}\BepInEx\plugins\${pluginName}\${pluginName}.dll")
    do {
        Copy-Item "bin\Debug\net46\${pluginName}.dll" "${gameFolder}\BepInEx\plugins\${pluginName}\${pluginName}.dll" -Force
    } until (Test-Path "${gameFolder}\BepInEx\plugins\${pluginName}\${pluginName}.dll")
    Start-Process "steam://rungameid/${appId}"
}
else {
    "Build failed"
}