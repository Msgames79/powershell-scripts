# https://github.com/constup/vdf-converter-powershell/blob/master/src%2Fvdf-converter.ps1
function ConvertTo-PSObject {
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

$flag = $true
$steampath = "$((Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath)\steamapps"
$vdfPSObject = ConvertTo-PSObject -vdfContent (Get-Content -Raw "${steampath}\libraryfolders.vdf")
for ($i = 0; $i -lt ($vdfPSObject.libraryfolders | Get-Member -membertype noteproperty).Count; $i++) {
    if ($vdfPSObject.libraryfolders."$i".apps.psobject.Properties["477160"]) {
        $hffpath = "$([Regex]::Replace(($vdfPSObject.libraryfolders."$i".path), "\\\\", "\"))\steamapps\common\Human Fall Flat"
        $flag = $false
        break
    }
}
if ($flag) {
    Write-Output "Human Fall Flat is not installed"
    Read-Host
    exit
}

Set-Location $hffpath

Remove-Item ("BepInEx", ".doorstop_version", "changelog.txt", "doorstop_config.ini", "winhttp.dll") -Recurse -Force
Invoke-RestMethod "https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.5/BepInEx_win_x86_5.4.23.5.zip" -outfile "BepInEx.zip"
Expand-Archive ".\BepInEx.zip" "."
Remove-Item ".\BepInEx.zip"
Start-Process "steam://rungameid/477160"
do {} until (Test-Path ".\BepInEx\plugins")
Stop-Process -Name "Human"
Set-Location ".\BepInEx\plugins"
Invoke-RestMethod "https://raw.githubusercontent.com/Msgames79/hffmods/refs/heads/main/plcc's%20timer/1.7.8.2/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87.zip" -outfile "plcc.zip"
Expand-Archive ".\plcc.zip" "."
Remove-Item ".\plcc.zip"
Invoke-RestMethod "https://github.com/Permamiss/HFF_SkipIntroLogos/releases/download/2.0.0/HFF_SkipIntroLogos.dll" -outfile "HFF_SkipIntroLogos.dll"
Invoke-RestMethod "https://raw.githubusercontent.com/Msgames79/hffmods/refs/heads/main/TASMod/1.17.18(Latest)/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87.zip" -outfile "tasmod.zip"
Expand-Archive ".\tasmod.zip" "."
Remove-Item ".\tasmod.zip"
Invoke-RestMethod "https://raw.githubusercontent.com/Msgames79/hffmods/refs/heads/main/Human%20Mod/1.5.23.2/Human%20Mod%20v1.5.23.2.zip" -outfile "humanmod.zip"
Expand-Archive ".\humanmod.zip" "."
Remove-Item ".\humanmod.zip"
Start-Process "steam://rungameid/477160"