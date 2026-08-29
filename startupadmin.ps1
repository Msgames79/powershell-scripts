chcp 65001
$ErrorActionPreference = 'SilentlyContinue'
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) {
    Start-Process -FilePath "wt.exe" -ArgumentList "pwsh -file $PSCommandPath" -Verb RunAs -WindowStyle Hidden
    exit
}
net start w32time
w32tm /config /update /manualpeerlist:ntp.nict.jp /syncfromflags:manual
w32tm /resync
if (((Get-Process | Where-Object {$_ -match "squaring_corner"}).Count) -eq 0) {
    Start-Process "$ENV:LOCALAPPDATA\SquareingCorner\squaring_corner.exe"
}
Get-ChildItem -Path "${ENV:USERPROFILE}Videos\deletethis" | Remove-Item -Force
Set-Location "C:\自分用\OBSPortable\Scripts"
Start-Process -FilePath "pwsh" -ArgumentList "-WindowStyle Hidden -file kidou.ps1"
Set-Location