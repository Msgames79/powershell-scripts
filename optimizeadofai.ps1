$adofaifile = "full path to file"
if (!(Test-Path $adofaifile) -or [System.IO.Path]::GetExtension($adofaifile) -ne ".adofai") {
    do {
        $adofaifile = Read-Host "full path to adofai file(you can drop an adofai file here)"
    } until (
        Test-Path $adofaifile -and [System.IO.Path]::GetExtension($adofaifile) -eq ".adofai"
    )
}
$pathtodir = [System.IO.Path]::GetDirectoryName($adofaifile)
$outpath = Join-Path $pathtodir "lightweight.adofai"
[int64]$i = 1
while (Test-Path $outpath) {
    $outpath = (Join-Path $pathtodir "lightweight${i}.adofai")
    $i++
}

$adofai = Get-Content $adofaifile | ConvertFrom-Json
$actions = $adofai.actions

$optactions = $actions | Where-Object { $_.eventType -cmatch "^(SetSpeed|Twirl|Checkpoint|SetHitsound|PlaySound|SetPlanetRotation|Pause|AutoPlayTiles|ScalePlanets|ColorTrack|AnimateTrack|RecolorTrack|MoveTrack|PositionTrack|SetText|SetDefaultText|Flash|MoveCamera|RepeatEvents|SetConditionalEvents|SetInputEvent|Hold|SetHoldSound|MultiPlanet|FreeRoam|PositionTrack|MoveCamera|FreeRoamTwirl|FreeRoamRemove|Hide|ScaleMargin|ScaleRadius)$" }

$optimized = [PSCustomObject]@{
    angleData   = $adofai.angleData
    settings    = $adofai.settings
    actions     = $optactions
    decorations = @()
}
$optimized | ConvertTo-Json -Depth 3 -Compress | Out-File $outpath

Write-Host "Created $([System.IO.Path]::GetFileName($outpath))`nEnter to exit"
Read-Host