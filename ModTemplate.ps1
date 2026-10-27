if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
    Write-Error -Message "Only for Windows"
    exit
}

try {
    if (([version](Invoke-Expression -Command "dotnet --version" -ErrorAction Stop)).Major -lt 6) {
        Invoke-RestMethod -Uri "https://dot.net/v1/dotnet-install.ps1" | Invoke-Expression
    }
}
catch {
    try {
        Invoke-RestMethod -Uri "https://dot.net/v1/dotnet-install.ps1" | Invoke-Expression
    }
    catch {
        Write-Error "An error occurred while installing .NET SDK."
        exit
    }
}

do {
    Invoke-Expression -Command "dotnet new install BepInEx.Templates@2.0.0-be.4 --nuget-source https://nuget.bepinex.dev/v3/index.json" -ErrorAction SilentlyContinue
    Invoke-Expression -Command "dotnet new list bepinex5plugin" -ErrorAction SilentlyContinue
} while ($LASTEXITCODE -eq 0)

Set-Location -Path $PSScriptRoot
do {
    Clear-Host
    $ProjectName = (Read-Host -Prompt "Enter your project name").Trim()
    while ([System.String]::IsNullOrEmpty($ProjectName) -or $ProjectName -match '[\\/:*?"<>|]') {
        Clear-Host
        $ProjectName = (Read-Host -Prompt "Previous input `"${ProjectName}`" is invalid string for directory`nEnter your project name").Trim()
    }
    $ProjectPath = "${PSScriptRoot}\${ProjectName}"
} until (-not (Test-Path -Path $ProjectPath) -or (Read-Host -Prompt "The directory `"${ProjectPath}`" already exists. Do you want to overwrite it?[y/n]").ToLower() -eq "y")

while (Test-Path -Path $ProjectPath) {
    Remove-Item -Path $ProjectPath -Recurse -Force
}

do {
    Invoke-Expression -Command "dotnet new bepinex5plugin -n ${ProjectName} -T net46 -U 2017.4.13"
} until ($LASTEXITCODE -eq 0)

Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Msgames79/powershell-scripts/refs/heads/main/debugmod.ps1" -OutFile "$ProjectPath\run.ps1"
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Msgames79/powershell-scripts/refs/heads/main/installmod.ps1" -OutFile "$ProjectPath\install.ps1"