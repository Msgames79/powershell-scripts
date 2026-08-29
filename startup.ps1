chcp 65001
$ErrorActionPreference = 'SilentlyContinue'
Start-Process -FilePath "explorer" -ArgumentList "C:\自分用"
Start-Process -FilePath "C:\Program Files\NVIDIA Corporation\NVIDIA Broadcast\NVIDIA Broadcast.exe"
python3 -m pip install -U pip hatchling wheel
$winget = (Start-Process -FilePath "winget" -ArgumentList "upgrade -ru" -NoNewWindow -PassThru).Id
Start-Process -FilePath "C:\Program Files\LGHUB\system_tray\lghub_system_tray.exe"
Set-Location "C:\Users\Msgames79\AppData\Local\Programs\Python\Python313\Scripts"
python3 -m pip install -U "yt-dlp[default]"
Remove-Item ((Join-Path $PWD.Path "ffmpeg.exe"), (Join-Path $PWD.Path "ffplay.exe"), (Join-Path $PWD.Path "ffprobe.exe"), (Join-Path $PWD.Path "ffmpeg.zip"), (Join-Path $PWD.Path "ffmpeg"), (Join-Path $PWD.Path "yt-dlp.exe")) -Recurse -Force -ErrorAction SilentlyContinue
if ((((Invoke-RestMethod "https://api.github.com/repos/GyanD/codexffmpeg/releases"), (Invoke-RestMethod "https://api.github.com/repos/BtbN/ffmpeg-builds/releases/latest")) | Sort-Object "published_at")[0].author.login -eq "GyanD") {
    #GyanDの場合
    $tag = (Invoke-RestMethod "https://api.github.com/repos/GyanD/codexffmpeg/releases" | Sort-Object "published_at")[0].tag_name
    Invoke-RestMethod "https://github.com/GyanD/codexffmpeg/releases/download/${tag}/ffmpeg-${tag}-full_build.zip" -OutFile (Join-Path $PWD.Path "ffmpeg.zip")
} else {
    #BtbNの場合
    Invoke-RestMethod "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -OutFile (Join-Path $PWD.Path "ffmpeg.zip")
}
$ffmpegzip = [System.IO.Compression.ZipFile]::Open((Join-Path $PWD.Path "ffmpeg.zip"), [System.IO.Compression.ZipArchiveMode]::Read)
try {
    $ffmpegzip.Entries | Where-Object {$_.FullName -like "*.exe"} | ForEach-Object {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, (Join-Path $PWD.Path ([System.IO.Path]::GetFileName($_.FullName))), $True)}
} finally {
    $ffmpegzip.Dispose()
}
Remove-Item ((Join-Path $PWD.Path "ffmpeg.zip"), (Join-Path $PWD.Path "ffmpeg")) -Recurse -Force -ErrorAction SilentlyContinue
Wait-Process -Id $winget
& ffplay -f lavfi -i "sine=f=1000"