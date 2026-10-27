$repoName = ""
$pluginName = ""
$appId = "477160"
$gameFolderName = "Human Fall Flat"
$ProcessName = "Human"
$owner = ""


# https://github.com/constup/vdf-converter-powershell/blob/master/src%2Fvdf-converter.ps1
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

if ($PSVersionTable.PSVersion.Major -eq 5 -or $IsWindows) {
    if (Test-Path "HKCU:\Software\Valve\Steam") {
        $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
    }
    else {
        Write-Error "Error 2: Steam is not installed"
        exit 2
    }
    if (Test-Path "${steamPath}\steamapps\libraryfolders.vdf") {
        $vdfPSObject = ConvertFrom-Vdf -vdfContent (Get-Content -Path "${steamPath}\steamapps\libraryfolders.vdf" -Raw)
    }
    else {
        Write-Error "Error 3: libraryfolders.vdf not found"
        exit 3
    }
    if (-not (Test-Path "HKCU:\Software\Valve\Steam\Apps\${appId}")) {
        Write-Error "Error 4: ${gameFolderName} is not installed"
        exit 4
    }
    if ((Get-ItemProperty "HKCU:\Software\Valve\Steam\Apps\${appId}").Installed -eq 0) {
        Write-Error "Error 4: ${gameFolderName} is not installed"
        exit 4
    }
    $flag = $true
    for ($i = 0; $i -lt ($vdfPSObject.libraryfolders | Get-Member -MemberType NoteProperty).Count; $i++) {
        if ($vdfPSObject.libraryfolders."${i}".apps."${appId}") {
            $gameFolder = "$([Regex]::Replace(($vdfPSObject.libraryfolders."$i".path), "\\\\", "\"))\steamapps\common\${gameFolderName}"
            $flag = $false
            break
        }
    }
    if ($flag) {
        Write-Error "Error 5: ${gameFolderName} is flagged as installed but not found"
        exit 5
    }
    Push-Location $gameFolder
    if (-not (Test-Path "BepInEx") -or -not (Test-Path ".doorstop_version") -or -not (Test-Path "changelog.txt") -or -not (Test-Path "doorstop_config.ini") -or -not (Test-Path "winhttp.dll") -or -not (Test-Path (Join-Path "BepInEx" "plugins"))) {
        $ErrorActionPreference = 'SilentlyContinue'
        Remove-Item ("BepInEx", ".doorstop_version", "changelog.txt", "doorstop_config.ini", "winhttp.dll") -Recurse -Force
        Invoke-RestMethod ((Invoke-RestMethod "https://api.github.com/repos/BepInEx/BepInEx/releases/latest").assets | Where-Object {$_.name -match "win" -and $_.name -match "x86"}).browser_download_url -OutFile "BepInEx.zip"
        Expand-Archive ".\BepInEx.zip" "."
        Remove-Item ".\BepInEx.zip"
        $ErrorActionPreference = 'Continue'
        Start-Process "steam://rungameid/${appId}"
        do {} until (Test-Path ".\BepInEx\plugins")
        Stop-Process -Name "${ProcessName}"
    }
    $ProgressPreference = 'SilentlyContinue'
    $latestApi = Invoke-WebRequest "https://api.github.com/repos/${owner}/${repoName}/releases/latest" -UseBasicParsing
    $ProgressPreference = 'Continue'
    if ([Math]::Truncate($latestApi.StatusCode / 100) -eq 2) {
        $latestJson = $latestApi.Content | ConvertFrom-Json
        $latestTagName = $latestJson.tag_name
        $latestFileApi = Invoke-WebRequest "https://github.com/${owner}/${repoName}/releases/download/${latestTagName}/${pluginName}-${latestTagName}.dll" -UseBasicParsing
        if ([Math]::Truncate($latestFileApi.StatusCode / 100) -eq 2) {
            if (Test-Path (Join-Path "BepInEx" "plugins" "${pluginName}-${latestTagName}.dll")) {
                if ("SHA256:" + (Get-FileHash (Join-Path "BepInEx" "plugins" "${pluginName}-${latestTagName}.dll") -Algorithm SHA256).Hash -eq $latestJson.assets.digest.ToUpper()) {
                    Write-Host "${pluginName} is up to date"
                    exit 0
                }
            }
            [System.IO.File]::WriteAllBytes((Join-Path $hffpath "BepInEx" "plugins" "${pluginName}-${latestTagName}.dll"), $latestFileApi.Content)
            Write-Host "Operation completed successfully."
            exit 0
        }
        else {
            Write-Error "Error 7: 'https://github.com/${owner}/${repoName}/releases/download/${latestTagName}/${pluginName}-${latestTagName}.dll' returned $($latestData.StatusCode)"
            exit 7
        }
    }
    else {
        Write-Error "Error 6: 'https://api.github.com/repos/${owner}/${repoName}/releases/latest' returned $($latestData.StatusCode)"
        exit 6
    }
}
else {
    Write-Error "Error 1: Only for Windows"
    exit 1
}