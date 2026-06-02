if ($PSVersionTable.PSVersion.Major -lt 7)
{
    "Run this script on Version 7 or newer`nhttps://github.com/PowerShell/PowerShell/releases/latest"
    Read-Host
    exit(1)
}
# Set-PSDebug -Trace 2
$ErrorActionPreference = 'SilentlyContinue'
$logtext = ""
$timer1 = @()
$threads = (Get-ComputerInfo).CsNumberOfLogicalProcessors
$timer = Measure-Command {
    Set-Location $PSScriptRoot
    $date = Get-Date
    $logtext += "Began at $($date.Year.ToString().PadLeft(4,"0"))-$($date.Month.ToString().PadLeft(2,"0"))-$($date.Day.ToString().PadLeft(2,"0")) $($date.Hour.ToString().PadLeft(2,"0")):$($date.Minute.ToString().PadLeft(2,"0")):$($date.Second.ToString().PadLeft(2,"0"))`nCleaning up files(1/9)..."
    Clear-Host
    Write-Host $logtext
    $timer1 += Measure-Command {
        while ((Get-Childitem -Name -Directory -Recurse | Where-Object {$_ -match "^(ncs\.io|musics)$"}).Count)
        {
            Get-Childitem -Name -Directory -Recurse | Where-Object {$_ -match "^(ncs\.io|musics)$"} | Remove-Item -Recurse -Force
        }
        while ((Get-Childitem -Name -File -Recurse | Where-Object {$_ -match "^(credits\.txt|wget2\.exe|7zr\.exe|ffmpeg\.7z|log\.txt|ncs.m3u|random.m3u)$"}).Count)
        {
            Get-Childitem -Name -File -Recurse | Where-Object {$_ -match "^(credits\.txt|wget2\.exe|7zr\.exe|ffmpeg\.7z|log\.txt|ncs.m3u|random.m3u)$"} | Remove-Item -Force -Recurse
        }
    }
    $logtext += "Done ($($timer1[0].Hours.ToString().PadLeft(2,"0")):$($timer1[0].Minutes.ToString().PadLeft(2,"0")):$($timer1[0].Seconds.ToString().PadLeft(2,"0")).$($timer1[0].Milliseconds.ToString().PadLeft(3,"0")))`nSetting up files(2/9)..."
    Clear-Host
    Write-Host $logtext
    $timer1 += Measure-Command {
        New-Item -ItemType Directory "musics","musics\temp" | Out-Null
        Invoke-RestMethod "https://github.com/rockdaboot/wget2/releases/latest/download/wget2.exe" -OutFile "wget2.exe"
        Invoke-RestMethod "https://www.7-zip.org/a/7zr.exe" -OutFile "7zr.exe"
        Invoke-RestMethod ("https://github.com/GyanD/codexffmpeg/releases/download/"+[regex]::Matches((Invoke-RestMethod "https://github.com/GyanD/codexffmpeg/tags"),"\d{4}-\d{2}-\d{2}-git-[0-9a-f]+")[0].Value+"/ffmpeg-"+[regex]::Matches((Invoke-RestMethod "https://github.com/GyanD/codexffmpeg/tags"),"\d{4}-\d{2}-\d{2}-git-[0-9a-f]+")[0].Value+"-full_build.7z") -OutFile "ffmpeg.7z"
        .\7zr.exe e -r -omusics\temp ffmpeg.7z ffmpeg.exe ffprobe.exe | Out-Null
    }
    $logtext += "Done ($($timer1[1].Hours.ToString().PadLeft(2,"0")):$($timer1[1].Minutes.ToString().PadLeft(2,"0")):$($timer1[1].Seconds.ToString().PadLeft(2,"0")).$($timer1[1].Milliseconds.ToString().PadLeft(3,"0")))`nDownloading HTMLs of each track(3/9)..."
    Clear-Host
    Write-Host $logtext
    $timer1 += Measure-Command {
        .\wget2.exe -q --max-threads $threads -r -X "artist,static,track,usage-policy" --reject-regex "artists|index|music|usage-policy|privacy|contact|AroundUs|about|favicon|robots" --no-robots ncs.io
    }
    $logtext += "Done ($($timer1[2].Hours.ToString().PadLeft(2,"0")):$($timer1[2].Minutes.ToString().PadLeft(2,"0")):$($timer1[2].Seconds.ToString().PadLeft(2,"0")).$($timer1[2].Milliseconds.ToString().PadLeft(3,"0")))`nExtracting data from HTMLs(4/9)..."
    Clear-Host
    Write-Host $logtext
    $timer1 += Measure-Command {
        Set-Location "ncs.io"
        $uuids = [System.Collections.ArrayList]::New()
        $artists = [System.Collections.ArrayList]::New()
        $genres = [System.Collections.ArrayList]::New()
        $tracks = [System.Collections.ArrayList]::New()
        $credits = [System.Collections.ArrayList]::New()
        Get-ChildItem | ForEach-Object {
            $a = New-Object -ComObject HTMLfile
            $a.write([system.text.encoding]::Unicode.GetBytes((Get-Content $_ -Raw)))
            $uuids.AddRange(@(@($a.getElementsByClassName("btn black")).nameprop)) | Out-Null
            $artists.Add([System.Net.WebUtility]::HtmlDecode([Regex]::matches(@($a.getElementsByClassName("btn black")).outerHTML,"data-artist=\`" *(.+?[^\\])\`"").Groups[-1].Value)) | Out-Null
            $genres.Add([System.Net.WebUtility]::HtmlDecode([Regex]::matches(@($a.getElementsByClassName("btn black")).outerHTML,"data-genre=\`" *(.+?[^\\])\`"").Groups[-1].Value)) | Out-Null
            $tracks.Add([System.Net.WebUtility]::HtmlDecode([Regex]::matches(@($a.getElementsByClassName("btn black")).outerHTML,"data-track=\`" *(.+?[^\\])\`"").Groups[-1].Value)) | Out-Null
            $credits.Add(@($a.GetElementsByClassName("p-copy")).innerText) | Out-Null
            if ($uuids[-1] -match "^i_")
            {
                $artists.Add([System.Net.WebUtility]::HtmlDecode([Regex]::matches(@($a.getElementsByClassName("btn black")).outerHTML,"data-artist=\`" *(.+?[^\\])\`"").Groups[-1].Value)) | Out-Null
                $genres.Add([System.Net.WebUtility]::HtmlDecode([Regex]::matches(@($a.getElementsByClassName("btn black")).outerHTML,"data-genre=\`" *(.+?[^\\])\`"").Groups[-1].Value)) | Out-Null
                $tracks.Add([System.Net.WebUtility]::HtmlDecode([Regex]::matches(@($a.getElementsByClassName("btn black")).outerHTML,"data-track=\`" *(.+?[^\\])\`"").Groups[-1].Value + " (Instrumental)")) | Out-Null
            }
            Remove-Variable a
        }
        Set-Location $PSScriptRoot
    }
    $logtext += "Done ($($timer1[3].Hours.ToString().PadLeft(2,"0")):$($timer1[3].Minutes.ToString().PadLeft(2,"0")):$($timer1[3].Seconds.ToString().PadLeft(2,"0")).$($timer1[3].Milliseconds.ToString().PadLeft(3,"0")))`nGenerating urls.txt(5/9)..."
    Clear-Host
    Write-Host $logtext
    $timer1 += Measure-Command {
        $uuids  | ForEach-Object {"https://ncs.io/track/download/${_}"} | Out-File "musics\temp\urls.txt"
    }
    $logtext += "Done ($($timer1[4].Hours.ToString().PadLeft(2,"0")):$($timer1[4].Minutes.ToString().PadLeft(2,"0")):$($timer1[4].Seconds.ToString().PadLeft(2,"0")).$($timer1[4].Milliseconds.ToString().PadLeft(3,"0")))`nGenerating credits.txt(6/9)..."
    Clear-Host
    Write-Host $logtext
    $timer1 += Measure-Command {
        $credits | Out-File "credits.txt"
        Remove-Variable "credits"
        Set-Location "musics\temp"
    }
    $logtext += "Done ($($timer1[5].Hours.ToString().PadLeft(2,"0")):$($timer1[5].Minutes.ToString().PadLeft(2,"0")):$($timer1[5].Seconds.ToString().PadLeft(2,"0")).$($timer1[5].Milliseconds.ToString().PadLeft(3,"0")))`nDownloading tracks(7/9)..."
    Clear-Host
    Write-Host $logtext
    $timer1 += Measure-Command {
        ..\..\wget2.exe -q --max-threads $threads --no-robots -i urls.txt
        while ((Get-Childitem -Name -File | Where-Object {$_ -match "^(urls\.txt)$"}).Count)
        {
            Get-Childitem -Name -File | Where-Object {$_ -match "^(urls\.txt)$"} | Remove-Item -Force
        }
    }
    $logtext += "Done ($($timer1[6].Hours.ToString().PadLeft(2,"0")):$($timer1[6].Minutes.ToString().PadLeft(2,"0")):$($timer1[6].Seconds.ToString().PadLeft(2,"0")).$($timer1[6].Milliseconds.ToString().PadLeft(3,"0")))`nRe-encoding tracks for more accurate data(8/9)..."
    Clear-Host
    Write-Host $logtext
    $timer1 += Measure-Command {
        0..($uuids.Count - 1) | Foreach-Object -ThrottleLimit $threads -Parallel {
            $uuids = $using:uuids
            $artists = $using:artists
            $tracks = $using:tracks
            $genres = $using:genres
            $pids = [System.Collections.Generic.List[int]]::New()
            $pids.Add((Start-Process ".\ffmpeg.exe" "-nostdin -v -8 -i $($uuids[$_]) -metadata artist=""$($artists[$_])"" -metadata title=""$($tracks[$_])"" -metadata genre=""$($genres[$_])"" -map a:0 -c:a libmp3lame -b:a 320k ..\$($uuids[$_]).mp3" -WindowStyle Hidden -PassThru).Id)
            Wait-Process -Id $pids
        }
        Set-Location $PSScriptRoot
    }
    $logtext += "Done ($($timer1[7].Hours.ToString().PadLeft(2,"0")):$($timer1[7].Minutes.ToString().PadLeft(2,"0")):$($timer1[7].Seconds.ToString().PadLeft(2,"0")).$($timer1[7].Milliseconds.ToString().PadLeft(3,"0")))`nCleaning up files(9/9)..."
    Clear-Host
    Write-Host $logtext
    $timer1 += Measure-Command {
        while ((Get-Childitem -Name -Directory -Recurse | Where-Object {$_ -match "^(ncs\.io|musics\\temp)$"}).Count)
        {
            Get-Childitem -Name -Directory -Recurse | Where-Object {$_ -match "^(ncs\.io|musics\\temp)$"} | Remove-Item -Recurse -Force
        }
        while ((Get-Childitem -Name -File -Recurse | Where-Object {$_ -match "^(wget2\.exe|7zr\.exe|ffmpeg\.7z)$"}).Count)
        {
            Get-Childitem -Name -File -Recurse | Where-Object {$_ -match "^(wget2\.exe|7zr\.exe|ffmpeg\.7z)$"} | Remove-Item -Force -Recurse
        }
        Get-ChildItem -n musics | ForEach-Object {"musics\${_}"} | Out-File "ncs.m3u"
        Get-Content ".\ncs.m3u" | Get-random -shuffle | Out-File ".\random.m3u"
    }
    $date = Get-Date
}

$logtext += "Done ($($timer1[8].Hours.ToString().PadLeft(2,"0")):$($timer1[8].Minutes.ToString().PadLeft(2,"0")):$($timer1[8].Seconds.ToString().PadLeft(2,"0")).$($timer1[8].Milliseconds.ToString().PadLeft(3,"0")))`nCompleted at $($date.Year.ToString().PadLeft(4,"0"))-$($date.Month.ToString().PadLeft(2,"0"))-$($date.Day.ToString().PadLeft(2,"0")) $($date.Hour.ToString().PadLeft(2,"0")):$($date.Minute.ToString().PadLeft(2,"0")):$($date.Second.ToString().PadLeft(2,"0"))`nCompleted this script in $((($timer.Hours).ToString()).PadLeft(2,"0")):$((($timer.Minutes).ToString()).PadLeft(2,"0")):$((($timer.Seconds).ToString()).PadLeft(2,"0")).$((($timer.Milliseconds).ToString()).PadLeft(3,"0"))"
Clear-Host
Write-Host $logtext
if ($env:username -eq "Msgames79")
{
    $logtext | Out-File "log.txt"
}
Write-Host "Enter to exit"
Read-Host