# Using vdf converter powered by constup.
# https://github.com/constup/vdf-converter-powershell/blob/master/src%2Fvdf-converter.ps1
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

if (-not (Test-Path "HKCU:\Software\Valve\Steam")) {
    Write-Output "Steam is not installed"
    Read-Host
}

$flag = $true
$steampath = Join-Path (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath "steamapps"
$vdfPSObject = ConvertFrom-Vdf -vdfContent (Get-Content -Raw (Join-Path "${steampath}" "libraryfolders.vdf"))
for ($i = 0; $i -lt ($vdfPSObject.libraryfolders | Get-Member -membertype noteproperty).Count; $i++) {
    if ($vdfPSObject.libraryfolders."$i".apps.psobject.Properties["477160"]) {
        $hffpath = Join-Path ([Regex]::Replace(($vdfPSObject.libraryfolders."$i".path), "\\\\", "\").ToString()) "steamapps\common\Human Fall Flat"
        $flag = $false
        break
    }
}
if ($flag) {
    Write-Output "Human Fall Flat is not installed"
    Read-Host
}

Set-Location $hffpath

while (Get-ItemPropertyValue "HKCU:\Software\Valve\Steam\Apps\477160" "Running") {
    Stop-Process -Name ("Human", "dnSpy") -ErrorAction SilentlyContinue
}
Remove-Item ("BepInEx", ".doorstop_version", "changelog.txt", "doorstop_config.ini", "winhttp.dll") -Recurse -Force -ErrorAction SilentlyContinue
$ProgressPreference = 'SilentlyContinue'
Invoke-RestMethod ((Invoke-RestMethod "https://api.github.com/repos/BepInEx/BepInEx/releases/latest").assets | Where-Object {$_.name -match "win" -and $_.name -match "x86"}).browser_download_url -OutFile "BepInEx.zip"
$ProgressPreference = 'Continue'
Expand-Archive ".\BepInEx.zip" "."
Remove-Item ".\BepInEx.zip"
Start-Process "steam://rungameid/477160"
do {} until (Test-Path ".\BepInEx\plugins")
Stop-Process -Name "Human"
Set-Location ".\BepInEx\plugins"
$ProgressPreference = 'SilentlyContinue'
Invoke-RestMethod "https://raw.githubusercontent.com/Msgames79/hffmods/refs/heads/main/plcc's%20timer/1.7.8.2/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87.zip" -outfile "plcc.zip"
Invoke-RestMethod "https://github.com/Permamiss/HFF_SkipIntroLogos/releases/download/2.0.0/HFF_SkipIntroLogos.dll" -outfile "HFF_SkipIntroLogos.dll"
Invoke-RestMethod "https://raw.githubusercontent.com/Msgames79/hffmods/refs/heads/main/TASMod/1.17.18(Latest)/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87.zip" -outfile "tasmod.zip"
Invoke-RestMethod "https://raw.githubusercontent.com/Msgames79/hffmods/refs/heads/main/Human%20Mod/1.5.23.2/Human%20Mod%20v1.5.23.2.zip" -outfile "humanmod.zip"
Invoke-RestMethod (Invoke-RestMethod "https://api.github.com/repos/Msgames79/achievementhelper/releases/latest").assets.browser_download_url -OutFile "AchievementHelper.dll"
Invoke-RestMethod (Invoke-RestMethod "https://api.github.com/repos/Msgames79/hff_revertbehavior/releases/latest").assets.browser_download_url -OutFile "hff_RevertBehavior.dll"
Invoke-RestMethod (Invoke-RestMethod "https://api.github.com/repos/Msgames79/ms-hff-tweaks/releases/latest").assets.browser_download_url -OutFile "Ms-HFF-Tweaks.dll"
$ProgressPreference = 'Continue'
Expand-Archive ".\plcc.zip" "."
Expand-Archive ".\tasmod.zip" "."
Expand-Archive ".\humanmod.zip" "."
Remove-Item ".\plcc.zip"
Remove-Item ".\tasmod.zip"
Remove-Item ".\humanmod.zip"
Start-Process "steam://rungameid/477160"