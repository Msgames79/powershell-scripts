function Install-FFmpeg {
    [CmdletBinding(DefaultParameterSetName = "static")]
    param (
        [Parameter(Mandatory = $True, Position = 0)][string]$ffmpegpath,
        [Parameter(ParameterSetName = "static")][switch]$static,
        [Parameter(ParameterSetName = "shared")][switch]$shared
    )
    $ErrorActionPreference = 'SilentlyContinue'
    $ProgressPreference = 'SilentlyContinue'
    $flag1 = $true
    [System.Console]::TreatControlCAsInput = $true
    if ((Get-Command ffmpeg).Count) {
        Write-Host "FFmpeg is already installed. Use Update-FFmpeg or Uninstall-FFmpeg instead." -ForegroundColor Red
        return
    }
    $ffmpegpath = Join-Path ([System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($ffmpegpath))) ([System.IO.Path]::GetFileNameWithoutExtension($ffmpegpath))
    Write-Host "Selected ${ffmpegpath}"
    if (-not (Test-Path -LiteralPath $ffmpegpath)) {
        Write-Host "This Directory does not exist. Do you want to create this Directory?(y/n)"
        do {
            $response = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } until (
            $response.Character -in ("y", "n")
        )
        if ($response.Character -eq "n") {
            Write-Host "Aborted."
            return
        }
        $flag1 = $false
        [void](New-Item -Path $ffmpegpath -ItemType Directory -Force)
    }
    if (-not ($ffmpegpath -in ($ENV:PATH -split ";" | ForEach-Object { $_.TrimEnd("\") }))) {
        if ($flag1) {
            Write-Host "The passed directory ${ffmpegpath} does not seem to be registered in PATH. Do you want to add this to PATH?(y/n)"
            do {
                $response = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            } until (
                $response.Character -in ("y", "n")
            )
            if ($response.Character -eq "n") {
                Write-Host "Aborted."
                return
            }
            Write-Host "Proceeded."
        }
        [System.Environment]::SetEnvironmentVariable("Path", ((([System.Environment]::GetEnvironmentVariable("Path", "User") -split ";"), "${ffmpegpath}") -join ";"), "User")
        $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
    Get-ChildItem -File $ffmpegpath | Where-Object { $_.name -match "^((avcodec|avdevice|avfilter|avformat|avutil|swresample|swscale)-\d+\.dll|ff(mpeg|play|probe)\.exe|ffmpeg\.zip)`$" } | Remove-Item -Force
    if ($shared) {
        $GyanDReleases = Invoke-RestMethod "https://api.github.com/repos/GyanD/codexffmpeg/releases/latest"
        $BtbNReleases = Invoke-RestMethod "https://api.github.com/repos/BtbN/ffmpeg-builds/releases/latest"
        $sorted = (($GyanDReleases, $BtbNReleases) | Sort-Object "published_at" -Descending)
        $tag = $sorted[0].tag_name
        if ($sorted[0].author.login -eq "GyanD") {
            Invoke-RestMethod "https://github.com/GyanD/codexffmpeg/releases/download/${tag}/ffmpeg-${tag}-full_build-shared.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
        }
        else {
            Invoke-RestMethod "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
        }
    }
    else {
        $GyanDReleases = Invoke-RestMethod "https://api.github.com/repos/GyanD/codexffmpeg/releases"
        $BtbNReleases = Invoke-RestMethod "https://api.github.com/repos/BtbN/ffmpeg-builds/releases/latest"
        $sorted = (($GyanDReleases, $BtbNReleases) | Sort-Object "published_at" -Descending)
        $tag = $sorted[0].tag_name
        if ($sorted[0].author.login -eq "GyanD") {
            Invoke-RestMethod "https://github.com/GyanD/codexffmpeg/releases/download/${tag}/ffmpeg-${tag}-full_build.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
        }
        else {
            Invoke-RestMethod "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
        }
    }
    $ffmpegzip = [System.IO.Compression.ZipFile]::Open((Join-Path $ffmpegpath "ffmpeg.zip"), [System.IO.Compression.ZipArchiveMode]::Read)
    try {
        $ffmpegzip.Entries | Where-Object { $_.FullName -match ".+/bin/.+" } | ForEach-Object { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, (Join-Path $ffmpegpath ([System.IO.Path]::GetFileName($_.FullName))), $True) }
    }
    finally {
        $ffmpegzip.Dispose()
    }
    Remove-Item (Join-Path $ffmpegpath "ffmpeg.zip") -Force
    Write-Host "Successfuly installed in ${ffmpegpath}"
    [System.Console]::TreatControlCAsInput = $false
}

function Update-FFmpeg {
    [CmdletBinding(DefaultParameterSetName = "Keep")]
    param (
        [Parameter(ParameterSetName = "static")][switch]$static,
        [Parameter(ParameterSetName = "shared")][switch]$shared,
        [Parameter(ParameterSetName = "keep")][switch]$keep
    )
    $ErrorActionPreference = 'SilentlyContinue'
    $ProgressPreference = 'SilentlyContinue'
    [System.Console]::TreatControlCAsInput = $true
    if ((Get-Command ffmpeg).Count -eq 0) {
        Write-Host "FFmpeg is not installed. Use Install-FFmpeg first." -ForegroundColor Red
        return
    }
    $ffmpegpath = Split-Path (Get-Command ffmpeg).Source
    Write-Host "Found FFmpeg in ${ffmpegpath}"
    while ((Get-Process | Where-Object { $_.Path -eq (Join-Path $ffmpegpath "ffmpeg.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffplay.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffprobe.exe") }).Count) {
        Write-Host "Waiting for $((Get-Process | Where-Object {$_.Path -eq (Join-Path $ffmpegpath "ffmpeg.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffplay.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffprobe.exe")})[0].Path)..."
        (Get-Process | Where-Object { $_.Path -eq (Join-Path $ffmpegpath "ffmpeg.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffplay.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffprobe.exe") })[0] | Wait-Process
    }
    if ($keep -and (Get-ChildItem -File $ffmpegpath | Where-Object {$_.name -match "^(avcodec|avdevice|avfilter|avformat|avutil|swresample|swscale)-\d+\.dll`$"}).Count) {
        $shared = $true
    }
    Get-ChildItem -File $ffmpegpath | Where-Object { $_.name -match "^((avcodec|avdevice|avfilter|avformat|avutil|swresample|swscale)-\d+\.dll|ff(mpeg|play|probe)\.exe|ffmpeg\.zip)`$" } | Remove-Item -Force
    if ($shared) {
        $GyanDReleases = Invoke-RestMethod "https://api.github.com/repos/GyanD/codexffmpeg/releases/latest"
        $BtbNReleases = Invoke-RestMethod "https://api.github.com/repos/BtbN/ffmpeg-builds/releases/latest"
        $sorted = (($GyanDReleases, $BtbNReleases) | Sort-Object "published_at" -Descending)
        $tag = $sorted[0].tag_name
        if ($sorted[0].author.login -eq "GyanD") {
            Invoke-RestMethod "https://github.com/GyanD/codexffmpeg/releases/download/${tag}/ffmpeg-${tag}-full_build-shared.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
        }
        else {
            Invoke-RestMethod "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
        }
    }
    else {
        $GyanDReleases = Invoke-RestMethod "https://api.github.com/repos/GyanD/codexffmpeg/releases"
        $BtbNReleases = Invoke-RestMethod "https://api.github.com/repos/BtbN/ffmpeg-builds/releases/latest"
        $sorted = (($GyanDReleases, $BtbNReleases) | Sort-Object "published_at" -Descending)
        $tag = $sorted[0].tag_name
        if ($sorted[0].author.login -eq "GyanD") {
            Invoke-RestMethod "https://github.com/GyanD/codexffmpeg/releases/download/${tag}/ffmpeg-${tag}-full_build.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
        }
        else {
            Invoke-RestMethod "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -OutFile (Join-Path $ffmpegpath "ffmpeg.zip")
        }
    }
    $ffmpegzip = [System.IO.Compression.ZipFile]::Open((Join-Path $ffmpegpath "ffmpeg.zip"), [System.IO.Compression.ZipArchiveMode]::Read)
    try {
        $ffmpegzip.Entries | Where-Object { $_.FullName -match ".+/bin/.+" } | ForEach-Object { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, (Join-Path $ffmpegpath ([System.IO.Path]::GetFileName($_.FullName))), $True) }
    }
    finally {
        $ffmpegzip.Dispose()
    }
    Remove-Item (Join-Path $ffmpegpath "ffmpeg.zip") -Recurse -Force
    Write-Host "Successfuly installed in ${ffmpegpath}"
    [System.Console]::TreatControlCAsInput = $false
}

function Uninstall-FFmpeg {
    [CmdletBinding()]
    $ErrorActionPreference = 'SilentlyContinue'
    [System.Console]::TreatControlCAsInput = $true
    if ((Get-Command ffmpeg).Count -eq 0) {
        Write-Host "FFmpeg is not installed. Nothing to do." -ForegroundColor Red
        return
    }
    while ((Get-Command ffmpeg -ErrorAction SilentlyContinue).Count) {
        $ffmpegpath = Split-Path (Get-Command ffmpeg).Source
        Write-Host "Found FFmpeg in ${ffmpegpath}"
        while ((Get-Process | Where-Object { $_.Path -eq (Join-Path $ffmpegpath "ffmpeg.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffplay.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffprobe.exe") }).Count) {
            Write-Host "Waiting for $((Get-Process | Where-Object {$_.Path -eq (Join-Path $ffmpegpath "ffmpeg.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffplay.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffprobe.exe")})[0].Path)..."
            (Get-Process | Where-Object { $_.Path -eq (Join-Path $ffmpegpath "ffmpeg.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffplay.exe") -or $_.Path -eq (Join-Path $ffmpegpath "ffprobe.exe") })[0] | Wait-Process
        }
        Get-ChildItem -File $ffmpegpath | Where-Object { $_.name -match "^((avcodec|avdevice|avfilter|avformat|avutil|swresample|swscale)-\d+\.dll|ff(mpeg|play|probe)\.exe|ffmpeg\.zip)`$" } | Remove-Item -Force
        if ((Get-ChildItem -File $ffmpegpath -Force).Count -eq 0) {
            Remove-Item -LiteralPath $ffmpegpath -Force
            [System.Environment]::SetEnvironmentVeriable("PATH", (([System.Environment]::GetEnvironmentVariable("PATH", "User") -split ";" | Where-Object { $_ -ne $ffmpeg }) -join ";"), "User")
            $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + [System.Environment]::GetEnvironmentVariable("Path", "User")
        }
    }
    Write-Host "Successfully uninstalled from ${ffmpegpath}"
    [System.Console]::TreatControlCAsInput = $false
}

#When invoked directly
#Can be used as module when loaded using dot sourcing
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Path -or (Resolve-Path $MyInvocation.InvocationName -ErrorAction SilentlyContinue).ProviderPath -eq $MyInvocation.MyCommand.Path) {
    $Choice1 = [System.Management.Automation.Host.ChoiceDescription]::new("&Install", "Install FFmpeg")
    $Choice2 = [System.Management.Automation.Host.ChoiceDescription]::new("&Update", "Update FFmpeg")
    $Choice3 = [System.Management.Automation.Host.ChoiceDescription]::new("Unins&tall", "Uninstall FFmpeg")
    $Choice4 = [System.Management.Automation.Host.ChoiceDescription]::new("&Quit", "Quit this script")
    $Choices1 = [System.Management.Automation.Host.ChoiceDescription[]]($Choice1, $Choice2, $Choice3, $Choice4)
    $Choice5 = [System.Management.Automation.Host.ChoiceDescription]::new("S&tatic", "Install static build")
    $Choice6 = [System.Management.Automation.Host.ChoiceDescription]::new("S&hared", "Install shared build")
    $Choice7 = [System.Management.Automation.Host.ChoiceDescription]::new("&Cancel", "Cancel and go back")
    $Choices2 = [System.Management.Automation.Host.ChoiceDescription[]]($Choice5, $Choice6, $Choice7)
    $Choice8 = [System.Management.Automation.Host.ChoiceDescription]::new("S&tatic", "Update to static build")
    $Choice9 = [System.Management.Automation.Host.ChoiceDescription]::new("S&hared", "Update to shared build")
    $Choice10 = [System.Management.Automation.Host.ChoiceDescription]::new("&Keep", "Update to current build")
    $Choice11 = [System.Management.Automation.Host.ChoiceDescription]::new("&Cancel", "Cancel and go back")
    $Choices3 = [System.Management.Automation.Host.ChoiceDescription[]]($Choice8, $Choice9, $Choice10, $Choice11)
    $flag2 = $true
    while ($flag2) {
        $response1 = $Host.UI.PromptForChoice("FFmpeg management script", "Choose what you want to (Default: Nothing)", $Choices1, -1)
        switch ($response1) {
            0 {
                $response2 = $Host.UI.PromptForChoice("Build selection", "Choose which version of FFmpeg do you want to install (Default: Cancel)", $Choices2, 2)
                switch ($response2) {
                    0 {
                        Install-FFmpeg -static
                    }
                    1 {
                        Install-FFmpeg -shared
                    }
                }
            }
            1 {
                $response3 = $Host.UI.PromptForChoice("Build selection", "Choose which version of FFmpeg do you want to update (Default: Keep)", $Choices3, 2)
                switch ($response3) {
                    0 {
                        Update-FFmpeg -static
                    }
                    1 {
                        Update-FFmpeg -shared
                    }
                    2 {
                        Update-FFmpeg -keep
                    }
                }
            }
            2 {
                Uninstall-FFmpeg
            }
            3 {
                Write-Host "Quitting. press any key."
                $null = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
                $flag2 = $false
            }
        }
    }
}