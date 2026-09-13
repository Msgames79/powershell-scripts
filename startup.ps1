chcp 65001
$ErrorActionPreference = 'SilentlyContinue'
& explorer "C:\自分用"
& explorer "C:\Program Files\NVIDIA Corporation\NVIDIA Broadcast\NVIDIA Broadcast.exe"
& "${ENV:LOCALAPPDATA}\Discord\Update.exe" --processStart Discord.exe
python3 -m pip install -U pip hatchling wheel
$winget = (Start-Process -FilePath "winget" -ArgumentList "upgrade -ru" -NoNewWindow -PassThru).Id
Start-Process -FilePath "C:\Program Files\LGHUB\system_tray\lghub_system_tray.exe"
Set-Location "C:\Users\Msgames79\AppData\Local\Programs\Python\Python313\Scripts"
python3 -m pip install -U "yt-dlp[default]"
Update-FFmpeg
Wait-Process -Id $winget
& ffplay -f lavfi -i "sine=f=1000"