$ffmpegpath = "${PSScriptRoot}"
Set-Location $ffmpegpath
Remove-Item ((Join-Path $ffmpegpath "ffmpeg.exe"), (Join-Path $ffmpegpath "ffplay.exe"), (Join-Path $ffmpegpath "ffprobe.exe"), (Join-Path $ffmpegpath "ffmpeg.zip"), (Join-Path $ffmpegpath "ffmpeg"), (Join-Path $ffmpegpath "yt-dlp.exe")) -Recurse -Force -ErrorAction SilentlyContinue
if ((((Invoke-RestMethod "https://api.github.com/repos/GyanD/codexffmpeg/releases" | Sort-Object "published_at")[-1], (Invoke-RestMethod "https://api.github.com/repos/BtbN/ffmpeg-builds/releases/latest")) | Sort-Object "published_at")[-1].author.login -eq "GyanD") {
    #GyanDの場合
    $tag = (Invoke-RestMethod "https://api.github.com/repos/GyanD/codexffmpeg/releases" | Sort-Object "published_at")[-1].tag_name
    Invoke-RestMethod "https://github.com/GyanD/codexffmpeg/releases/download/${tag}/ffmpeg-${tag}-full_build.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
} else {
    #BtbNの場合
    Invoke-RestMethod "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
}
$ffmpegzip = [System.IO.Compression.ZipFile]::Open((Join-Path $PWD "ffmpeg.zip"), [System.IO.Compression.ZipArchiveMode]::Read)
try {
    $ffmpegzip.Entries | Where-Object {$_.FullName -like "*.exe"} | ForEach-Object {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, (Join-Path $ffmpegpath ([System.IO.Path]::GetFileName($_.FullName))), $True)}
} finally {
    $ffmpegzip.Dispose()
}
Invoke-RestMethod "https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp.exe" -OutFile (Join-Path $ffmpegpath "yt-dlp.exe")
Remove-Item ((Join-Path $ffmpegpath "ffmpeg.zip"), (Join-Path $ffmpegpath "ffmpeg")) -Recurse -Force -ErrorAction SilentlyContinue 